# 🚀 Field Watch Deployment Guide

This guide details all ways to deploy the **Field Watch** farm safety system across local machines, Docker containers, cloud hosting platforms, and field edge devices.

---

## 1. Local Deployment (Windows, Linux, macOS)

### Quick Launch on Windows
The project includes pre-configured batch scripts that use the embedded Python environment and Node.js:
- **Both services simultaneously**: Double-click `start_all.bat` or run:
  ```powershell
  .\start_all.ps1
  ```
- **Backend only**: Double-click `start_backend.bat`
- **Frontend only**: Double-click `start_frontend.bat`

### Manual CLI Launch
#### Backend (FastAPI)
```bash
cd backend
# Using embedded Python:
..\python_embed\python.exe -m uvicorn main:app --app-dir . --reload --port 8000
# Or using system Python:
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
- API Endpoint: `http://localhost:8000`
- Swagger Documentation: `http://localhost:8000/docs`
- Interactive OpenAPI spec: `http://localhost:8000/redoc`

#### Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
```
- Dashboard URL: `http://localhost:5173`

---

## 2. Docker & Docker Compose Deployment

A complete container setup with multi-stage production builds and an Nginx reverse proxy is included.

### Prerequisites
- Docker & Docker Compose installed.

### Commands
```bash
# Build and run containers in detached mode
docker compose up --build -d

# Check running status
docker compose ps

# View live application logs
docker compose logs -f

# Stop containers
docker compose down
```

### Port Mapping & Architecture
- **Frontend & Proxy**: `http://localhost:3000` (Nginx proxies `/api` and `/ws` to the backend container)
- **Backend API**: `http://localhost:8000`
- **Database Persistence**: SQLite database `events.db` is persisted via named Docker volume `farm-data`.

---

## 3. Cloud Deployment

### A. One-Click Blueprint on Render (Recommended for full stack)
Both services are defined in `render.yaml`.
1. Push your repository to GitHub / GitLab.
2. Sign in to [Render](https://render.com).
3. Click **New +** -> **Blueprint**.
4. Connect your repository.
5. Render will automatically provision:
   - `farm-safety-backend` (FastAPI Python Web Service)
   - `farm-safety-frontend` (Static Site with SPA rewrite rules)
6. Once deployed, set `VITE_API_URL` in the frontend environment to your backend URL (e.g., `https://farm-safety-backend.onrender.com`).

---

### B. Frontend on Vercel / Netlify + Backend on Railway / Render

#### Deploy Frontend on Vercel:
1. Import repository on [Vercel](https://vercel.com).
2. Set **Root Directory** to `frontend`.
3. Framework preset: **Vite**.
4. Add Environment Variable:
   - `VITE_API_URL`: Your backend URL (e.g., `https://your-backend.up.railway.app`)
5. Click **Deploy**. SPA client routing is handled by `frontend/vercel.json`.

#### Deploy Backend on Railway:
1. Create a new project on [Railway](https://railway.app).
2. Select **Deploy from GitHub repo**.
3. Set **Root Directory** to `backend`.
4. Railway will automatically detect `Procfile` (`web: uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}`).
5. Add any necessary environment variables in Railway's Variables tab.

---

### C. Self-Hosted VPS (Ubuntu / Debian / EC2 / Droplet)

1. **Install dependencies**:
   ```bash
   sudo apt update && sudo apt install -y python3-pip python3-venv nodejs npm nginx
   ```
2. **Setup Systemd service for Backend** (`/etc/systemd/system/farm-backend.service`):
   ```ini
   [Unit]
   Description=Farm Safety FastAPI Backend
   After=network.target

   [Service]
   User=ubuntu
   WorkingDirectory=/var/www/farm-safety-project/backend
   ExecStart=/usr/local/bin/uvicorn main:app --host 127.0.0.1 --port 8000
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```
3. **Build Frontend**:
   ```bash
   cd frontend
   npm install
   npm run build
   ```
4. **Configure Nginx** to serve `dist/` and proxy `/api/` and `/ws/` to `127.0.0.1:8000`.

---

## 4. Edge Device Deployment (Raspberry Pi / Jetson)

The edge inference unit is located in `backend/edge/edge_node.py`.

### Setup on Raspberry Pi:
```bash
pip install ultralytics opencv-python requests
```
In `backend/edge/edge_node.py`, configure:
- `API`: URL of your deployed backend (e.g. `https://your-backend-domain.com/api/events`)
- `KEY`: Matching `DEVICE_API_KEY` (default: `dev-key`)
- `DEVICE`: Identifier for field unit (e.g. `node-01`, `fence-north`)
- `ZONE`: Field zone (e.g. `North fence`, `Water pump`)

Run the edge detector:
```bash
python edge/edge_node.py
```

---

## 5. Environment Variables Reference

| Variable | Default | Description |
|---|---|---|
| `DEVICE_API_KEY` | `dev-key` | Authentication header (`x-api-key`) expected from field units |
| `CONFIRM_THRESHOLD` | `0.6` | Detection confidence threshold (0.0 - 1.0) to mark alerts as confirmed and trigger SMS |
| `DB_PATH` | `events.db` | SQLite database file location |
| `FARMER_PHONE` | _Optional_ | Phone number to receive SMS alerts (e.g. `+91XXXXXXXXXX`) |
| `TWILIO_SID` | _Optional_ | Twilio Account SID |
| `TWILIO_TOKEN` | _Optional_ | Twilio Auth Token |
| `TWILIO_FROM` | _Optional_ | Twilio source phone number |
| `VITE_API_URL` | `http://localhost:8000` | Backend URL used by React frontend (empty in dev proxies to localhost:8000) |
