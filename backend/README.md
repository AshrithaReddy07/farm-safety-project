# Field Watch – Backend (FastAPI)
1. `pip install -r requirements.txt`
2. `uvicorn main:app --reload --port 8000`   (docs at /docs)

Environment variables: DEVICE_API_KEY, CONFIRM_THRESHOLD (default 0.6), FARMER_PHONE,
TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM, DB_PATH.
The field unit script is in `edge/edge_node.py` (set API URL and key inside it).
CORS is open to all origins for development; restrict `allow_origins` in `main.py` for production.
