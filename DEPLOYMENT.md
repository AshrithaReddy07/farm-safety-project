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

---

## 3. GitHub Repository Setup

Before deploying to Railway, your project needs to be hosted on GitHub.

### Step 1: Create a GitHub Repository
1. Log in to [GitHub](https://github.com) and click **New Repository** (or visit `https://github.com/new`).
2. Set repository name (e.g., `farm-safety-system` or `farm-safety-project`).
3. Set visibility to **Public** or **Private**.
4. **Do NOT check** "Initialize with README", ".gitignore", or "license" (your local project already contains these).
5. Click **Create repository**.

### Step 2: Push Your Local Code to GitHub
Open your terminal in the project root (`C:\Users\ashri\Downloads\farm-safety-project`) and run:
```bash
# Set your remote repository URL (replace with your GitHub repo URL)
git remote add origin https://github.com/<YOUR-USERNAME>/<YOUR-REPO-NAME>.git

# Ensure main branch is selected
git branch -M main

# Push code to GitHub
git push -u origin main
```
*(Or simply run `.\push_to_github.bat` which will prompt for your GitHub URL and push automatically.)*

---

## 4. Railway Deployment (FastAPI + React Monorepo)

Railway is optimized for cloud microservices and provides automated SSL, CI/CD on git push, and persistent disks.

### Option A: Full-Stack Deployment on Railway (Recommended)

You deploy both the FastAPI backend and React frontend as two services inside one Railway project.

#### 1. Deploy the Backend Service
1. Log in to [Railway](https://railway.app) (sign in with GitHub).
2. Click **New Project** -> **Deploy from GitHub repo**.
3. Select your repository.
4. When the service card appears, click on it, go to **Settings**:
   - **Service Name**: Rename to `farm-safety-backend`.
   - **Root Directory**: Set to `/backend`.
5. Under **Variables**, add optional keys:
   - `DEVICE_API_KEY`: `dev-key` (or your secret key)
   - `CONFIRM_THRESHOLD`: `0.6`
   - *(Optional Twilio keys)*: `TWILIO_SID`, `TWILIO_TOKEN`, `TWILIO_FROM`, `FARMER_PHONE`
6. Under **Networking**:
   - Click **Generate Domain** (e.g., `https://farm-safety-backend.up.railway.app`).
   - Copy this URL.
7. *(Optional Persistent Storage)*:
   - Go to **Volumes** tab -> Click **Add Volume**.
   - Set mount path: `/data`.
   - In Variables, set `DB_PATH=/data/events.db` so database records survive redeployments.

#### 2. Deploy the Frontend Service
1. In the same Railway project canvas, click **+ New** -> **GitHub Repo**.
2. Select the **same** repository again.
3. Click the new service card, go to **Settings**:
   - **Service Name**: Rename to `farm-safety-frontend`.
   - **Root Directory**: Set to `/frontend`.
4. Go to **Variables**, add:
   - `VITE_API_URL`: Your backend URL from step 1 (e.g., `https://farm-safety-backend.up.railway.app`).
5. Under **Networking**:
   - Click **Generate Domain** (e.g., `https://farm-safety-frontend.up.railway.app`).
6. Click the generated frontend URL to open the live Field Watch Dashboard!

---

### Option B: Backend on Railway + Frontend on Vercel

If you want to take advantage of Vercel's global CDN for the frontend:

1. **Backend on Railway**: Follow steps 1-7 in Option A above.
2. **Frontend on Vercel**:
   - Go to [Vercel](https://vercel.com) -> **Add New...** -> **Project**.
   - Select your GitHub repo.
   - Set **Root Directory** to `frontend`.
   - Add Environment Variable: `VITE_API_URL` = `https://your-backend.up.railway.app`.
   - Click **Deploy**.

---

## 5. Other Cloud & Hosting Options

### A. One-Click Blueprint on Render
Both services are defined in `render.yaml`.
1. Push your repository to GitHub.
2. Sign in to [Render](https://render.com).
3. Click **New +** -> **Blueprint**.
4. Connect your repository.
5. Render will automatically provision both backend and frontend.

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
