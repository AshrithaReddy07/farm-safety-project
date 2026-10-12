import { useCallback, useEffect, useState } from "react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";

const API = (import.meta.env.VITE_API_URL || "").replace(/\/$/, "");
const WS = API ? API.replace(/^http/, "ws") : `${location.protocol === "https:" ? "wss" : "ws"}://${location.host}`;

const CATS = {
  animal: { label: "Wild animal", color: "var(--animal)" },
  intruder: { label: "Intruder", color: "var(--intruder)" },
  fire: { label: "Fire or smoke", color: "var(--fire)" },
  machinery: { label: "Machinery hazard", color: "var(--machinery)" },
};

const ago = (ts) => {
  const s = Math.max(0, (Date.now() - new Date(ts)) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  return new Date(ts).toLocaleDateString();
};

export default function App() {
  const [events, setEvents] = useState([]);
  const [stats, setStats] = useState(null);
  const [filter, setFilter] = useState("all");
  const [live, setLive] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try {
      const [e, s] = await Promise.all([
        fetch(`${API}/api/events?limit=100`).then((r) => r.json()),
        fetch(`${API}/api/stats`).then((r) => r.json()),
      ]);
      setEvents(e); setStats(s); setError("");
    } catch {
      setError("Can't reach the server. Check that the backend is running and VITE_API_URL is correct.");
    }
  }, []);

  useEffect(() => {
    load();
    let ws, timer, closed = false;
    const connect = () => {
      ws = new WebSocket(`${WS}/ws/live`);
      ws.onopen = () => setLive(true);
      ws.onmessage = load;
      ws.onclose = () => { setLive(false); if (!closed) timer = setTimeout(connect, 3000); };
    };
    connect();
    return () => { closed = true; clearTimeout(timer); ws && ws.close(); };
  }, [load]);

  const seed = async () => { await fetch(`${API}/api/demo/seed`, { method: "POST" }); load(); };
  const shown = events.filter((e) => filter === "all" || e.category === filter);
  const recent = stats?.last_hour ?? 0;
  const latest = events.find((e) => e.confirmed);
  const hours = (stats?.by_hour ?? []).map((n, h) => ({ h: String(h).padStart(2, "0"), n }));
  const peak = Math.max(0, ...hours.map((d) => d.n));

  return (
    <div className="wrap">
      <header className={`status ${recent ? "warn" : ""}`}>
        <div>
          <h1>{recent ? `${recent} threat${recent > 1 ? "s" : ""} in the last hour` : "All quiet"}</h1>
          <p>{recent && latest ? `Latest: ${latest.label} at ${latest.zone}` : "No confirmed threats in the last hour."}</p>
        </div>
        <span><i className={`dot ${live ? "" : "off"}`} />{live ? "Live" : "Reconnecting"}</span>
      </header>

      {error && <p role="alert" className="panel" style={{ marginTop: 16 }}>{error}</p>}

      <div className="grid">
        <section className="panel" aria-labelledby="feed">
          <h2 id="feed">Detections</h2>
          <div className="chips">
            {["all", ...Object.keys(CATS)].map((c) => (
              <button key={c} className="chip" aria-pressed={filter === c} onClick={() => setFilter(c)}>
                {c === "all" ? "All" : CATS[c].label}
              </button>
            ))}
          </div>
          {shown.length === 0 && (
            <div className="empty">
              <p className="muted">No detections yet. Once a field unit reports, they appear here.</p>
              <button onClick={seed}>Load sample detections</button>
            </div>
          )}
          {shown.map((e) => (
            <article key={e.id} className={`ev ${e.confirmed ? "" : "low"}`}>
              <span className="bar" style={{ background: CATS[e.category].color }} />
              <div>
                <strong>{CATS[e.category].label}: {e.label}</strong>
                <small>{e.zone} · {Math.round(e.confidence * 100)}% sure{e.confirmed ? "" : " (not alerted)"}</small>
              </div>
              <small>{ago(e.ts)}</small>
            </article>
          ))}
        </section>

        <div style={{ display: "grid", gap: 16, alignContent: "start" }}>
          <section className="panel" aria-labelledby="hrs">
            <h2 id="hrs">When threats happen (UTC, last 30 days)</h2>
            <div style={{ height: 180 }}>
              <ResponsiveContainer>
                <BarChart data={hours}>
                  <XAxis dataKey="h" tick={{ fontSize: 10 }} interval={2} />
                  <YAxis allowDecimals={false} width={24} tick={{ fontSize: 10 }} />
                  <Tooltip />
                  <Bar dataKey="n" name="Threats" radius={[3, 3, 0, 0]}>
                    {hours.map((d) => <Cell key={d.h} fill={d.n === peak && peak > 0 ? "#c62828" : "#2f6b45"} />)}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </section>

          <section className="panel" aria-labelledby="zn">
            <h2 id="zn">Where threats happen most</h2>
            {(stats?.by_zone ?? []).length === 0 && <p className="muted">No data yet.</p>}
            <ul className="zones">
              {(stats?.by_zone ?? []).map(([zone, n]) => <li key={zone}><span>{zone}</span><strong>{n}</strong></li>)}
            </ul>
          </section>
        </div>
      </div>
    </div>
  );
}
