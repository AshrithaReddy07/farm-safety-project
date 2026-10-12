# 🌾 Field Watch — Farm Safety Monitoring System

Field Watch is a real-time farm safety and perimeter monitoring system. It detects threats (wild animals, intruders, fire/smoke, machinery hazards) at field edge devices and streams alerts to a central dashboard and SMS notifications.

---

## 🚀 Quick Start (Local)

### Option 1: One-Click Launch (Windows)
Double-click `start_all.bat` (or run `.\start_all.ps1` in PowerShell). This launches:
- **Backend API**: [http://localhost:8000](http://localhost:8000) (Interactive Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs))
- **Frontend Dashboard**: [http://localhost:5173](http://localhost:5173)

### Option 2: Individual Launch Scripts
- Backend only: Run `start_backend.bat`
- Frontend only: Run `start_frontend.bat`

---

## 🐳 Docker Deployment

To run both services in containers with persistent storage and Nginx reverse proxy:

```bash
docker compose up --build -d
```

- **Frontend Dashboard**: [http://localhost:3000](http://localhost:3000)
- **Backend API**: [http://localhost:8000](http://localhost:8000)

---

## ☁️ Cloud Deployment

- **Render**: Connect your GitHub repository and select **New + Blueprint Instance**. Render reads `render.yaml` and deploys both the FastAPI backend and React frontend.
- **Vercel / Netlify**: Deploy the `frontend` directory (pre-configured with `frontend/vercel.json`). Set `VITE_API_URL` to your backend URL.
- **Railway**: Connect the `backend` directory (pre-configured with `backend/Procfile`).

See [DEPLOYMENT.md](DEPLOYMENT.md) for full deployment instructions and environment variables.

---

## 📁 Project Architecture

```
farm-safety-project/
├── backend/
│   ├── edge/
│   │   └── edge_node.py       # Edge camera/YOLO inference script
│   ├── main.py                # FastAPI REST API & WebSocket server
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile             # Backend container spec
│   ├── Procfile               # Cloud process spec
│   └── .env.example           # Backend environment template
├── frontend/
│   ├── src/
│   │   ├── App.jsx            # React dashboard & live event stream
│   │   ├── main.jsx           # React DOM root
│   │   └── styles.css         # Dashboard styles
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js         # Dev server with proxy to :8000
│   ├── Dockerfile             # Multi-stage production container
│   ├── nginx.conf             # Production Nginx reverse proxy
│   └── vercel.json            # Vercel SPA routing
├── docker-compose.yml         # Container orchestration
├── render.yaml                # Render Cloud Blueprint
├── start_all.bat              # One-click Windows launcher
├── start_all.ps1              # One-click PowerShell launcher
├── start_backend.bat          # Backend launcher
├── start_frontend.bat         # Frontend launcher
└── DEPLOYMENT.md              # Full deployment manual
```
