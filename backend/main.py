"""Farm safety backend. Run: uvicorn main:app --reload --port 8000"""
import os, random, sqlite3
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Literal, Optional

from fastapi import FastAPI, Header, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

DB = os.getenv("DB_PATH", "events.db")
API_KEY = os.getenv("DEVICE_API_KEY", "dev-key")
THRESHOLD = float(os.getenv("CONFIRM_THRESHOLD", "0.6"))
FARMER_PHONE = os.getenv("FARMER_PHONE")  # e.g. +91XXXXXXXXXX
Category = Literal["animal", "intruder", "fire", "machinery"]

app = FastAPI(title="Farm Safety API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def db():
    db_dir = os.path.dirname(DB)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    return con


with db() as con:
    con.execute("""CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT, device_id TEXT, category TEXT, label TEXT,
        confidence REAL, confirmed INTEGER, zone TEXT, lat REAL, lng REAL,
        image_url TEXT, ts TEXT)""")


class EventIn(BaseModel):
    device_id: str
    category: Category
    label: str
    confidence: float = Field(ge=0, le=1)
    zone: str = "Main field"
    lat: Optional[float] = None
    lng: Optional[float] = None
    image_url: Optional[str] = None
    ts: Optional[datetime] = None


class Hub:
    def __init__(self):
        self.clients: list[WebSocket] = []

    async def broadcast(self, msg: dict):
        for ws in list(self.clients):
            try:
                await ws.send_json(msg)
            except Exception:
                self.clients.remove(ws)


hub = Hub()


def send_sms(text: str):
    sid, tok, frm = (os.getenv(k) for k in ("TWILIO_SID", "TWILIO_TOKEN", "TWILIO_FROM"))
    if not (sid and tok and frm and FARMER_PHONE):
        print("[ALERT]", text)  # Twilio not configured: log only
        return
    from twilio.rest import Client
    Client(sid, tok).messages.create(to=FARMER_PHONE, from_=frm, body=text)


def insert(e: EventIn) -> dict:
    ts = (e.ts or datetime.now(timezone.utc)).isoformat()
    confirmed = int(e.confidence >= THRESHOLD)
    with db() as con:
        cur = con.execute(
            "INSERT INTO events (device_id,category,label,confidence,confirmed,zone,lat,lng,image_url,ts) VALUES (?,?,?,?,?,?,?,?,?,?)",
            (e.device_id, e.category, e.label, e.confidence, confirmed, e.zone, e.lat, e.lng, e.image_url, ts))
        row = con.execute("SELECT * FROM events WHERE id=?", (cur.lastrowid,)).fetchone()
    return dict(row)


STATIC_DIR = os.getenv("STATIC_DIR")
if not STATIC_DIR:
    for _cand in [
        os.path.join(os.path.dirname(__file__), "static"),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")),
    ]:
        if os.path.isdir(_cand) and os.path.exists(os.path.join(_cand, "index.html")):
            STATIC_DIR = _cand
            break


@app.get("/")
def root():
    if STATIC_DIR and os.path.exists(os.path.join(STATIC_DIR, "index.html")):
        from starlette.responses import FileResponse
        return FileResponse(os.path.join(STATIC_DIR, "index.html"))
    return {
        "status": "online",
        "service": "Farm Safety API",
        "docs": "/docs",
        "endpoints": {
            "events": "/api/events",
            "stats": "/api/stats",
            "live_websocket": "/ws/live",
            "seed_demo": "/api/demo/seed"
        }
    }


@app.get("/health")
def health():
    return {"status": "ok", "service": "Farm Safety API"}


@app.post("/api/events", status_code=201)
async def ingest(e: EventIn, x_api_key: str = Header(default="")):
    if x_api_key != API_KEY:
        raise HTTPException(401, "Invalid device key")
    ev = insert(e)
    if ev["confirmed"]:
        send_sms(f"{e.category.upper()}: {e.label} in {e.zone} ({int(e.confidence*100)}%) at {ev['ts'][11:16]} UTC")
    await hub.broadcast(ev)
    return ev


@app.get("/api/events")
def list_events(limit: int = 100, category: Optional[Category] = None, confirmed_only: bool = False):
    q, args = "SELECT * FROM events WHERE 1=1", []
    if category:
        q += " AND category=?"; args.append(category)
    if confirmed_only:
        q += " AND confirmed=1"
    q += " ORDER BY ts DESC LIMIT ?"; args.append(min(limit, 500))
    with db() as con:
        return [dict(r) for r in con.execute(q, args)]


@app.get("/api/stats")
def stats(days: int = 30):
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    with db() as con:
        rows = [dict(r) for r in con.execute("SELECT * FROM events WHERE confirmed=1 AND ts>=?", (since,))]
    hours = Counter(int(r["ts"][11:13]) for r in rows)
    last_hour = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    return {
        "total": len(rows),
        "last_hour": sum(r["ts"] >= last_hour for r in rows),
        "by_category": dict(Counter(r["category"] for r in rows)),
        "by_zone": Counter(r["zone"] for r in rows).most_common(5),
        "by_hour": [hours.get(h, 0) for h in range(24)],  # UTC hours
    }


@app.post("/api/demo/seed")
def seed():
    zones = ["North fence", "East boundary", "Water pump", "Barn yard", "Main field"]
    labels = {"animal": ["wild boar", "elephant", "stray dog"], "intruder": ["person"],
              "fire": ["flame"], "machinery": ["tractor near worker"]}
    now = datetime.now(timezone.utc)
    for _ in range(60):
        cat = random.choices(list(labels), [6, 3, 1, 2])[0]
        hr = random.choice([4, 5, 19, 20, 21, 22, 2, 12])
        ts = (now - timedelta(days=random.randint(1, 9))).replace(hour=hr, minute=random.randint(0, 59))
        insert(EventIn(device_id="node-01", category=cat, label=random.choice(labels[cat]),
                       confidence=round(random.uniform(0.45, 0.97), 2), zone=random.choice(zones), ts=ts))
    return {"seeded": 60}


@app.websocket("/ws/live")
async def live(ws: WebSocket):
    await ws.accept()
    hub.clients.append(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        if ws in hub.clients:
            hub.clients.remove(ws)


# Serve frontend static assets & SPA routes if available
if STATIC_DIR and os.path.isdir(STATIC_DIR):
    from fastapi.staticfiles import StaticFiles
    from starlette.responses import FileResponse

    _assets = os.path.join(STATIC_DIR, "assets")
    if os.path.isdir(_assets):
        app.mount("/assets", StaticFiles(directory=_assets), name="assets")

    @app.get("/{full_path:path}")
    def serve_spa(full_path: str):
        if full_path.startswith("api/") or full_path.startswith("ws/") or full_path in ("docs", "redoc", "openapi.json", "health"):
            raise HTTPException(status_code=404, detail="Not Found")
        file_path = os.path.join(STATIC_DIR, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        index_file = os.path.join(STATIC_DIR, "index.html")
        if os.path.isfile(index_file):
            return FileResponse(index_file)
        raise HTTPException(status_code=404, detail="Not Found")

