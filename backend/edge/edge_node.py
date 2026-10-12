"""Field unit (Raspberry Pi). pip install ultralytics opencv-python requests
Swap yolov8n.pt for your Roboflow-trained model to detect fire and local wildlife."""
import time, cv2, requests
from ultralytics import YOLO

API = "http://YOUR_SERVER:8000/api/events"
KEY, DEVICE, ZONE = "dev-key", "node-01", "North fence"
COOLDOWN = 30  # seconds between alerts of the same category
CLASS_MAP = {"person": "intruder", "truck": "machinery", "car": "machinery",
             "bear": "animal", "elephant": "animal", "dog": "animal", "zebra": "animal",
             "fire": "fire"}  # "fire" needs a custom-trained class

model, cam, last = YOLO("yolov8n.pt"), cv2.VideoCapture(0), {}
while True:
    ok, frame = cam.read()
    if not ok:
        time.sleep(1); continue
    for box in model(frame, verbose=False)[0].boxes:
        label = model.names[int(box.cls)]
        cat = CLASS_MAP.get(label)
        if not cat or time.time() - last.get(cat, 0) < COOLDOWN:
            continue
        last[cat] = time.time()
        try:
            requests.post(API, headers={"x-api-key": KEY}, timeout=5, json={
                "device_id": DEVICE, "category": cat, "label": label,
                "confidence": float(box.conf), "zone": ZONE})
        except requests.RequestException:
            pass  # TODO: fall back to SIM800L SMS when offline
    time.sleep(0.2)
