"""
HeartShield - Worker Enrollment
Use this to register NHAI workers into the system.
Run BEFORE using heartshield.py
"""

import cv2
import sys
import os

# Add parent dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from heartshield import FaceDetector, FaceRecognizer, SunlightPreprocessor

def enroll_worker():
    print("=" * 50)
    print("  HeartShield — Worker Enrollment")
    print("=" * 50)

    worker_id = input("\nEnter Worker ID (e.g., NHAI_001): ").strip()
    worker_name = input("Enter Worker Name: ").strip()

    if not worker_id or not worker_name:
        print("❌ Worker ID and Name are required")
        return

    detector = FaceDetector()
    recognizer = FaceRecognizer()
    preprocessor = SunlightPreprocessor()

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ Cannot open webcam")
        return

    print(f"\n📷 Enrolling: {worker_name} (ID: {worker_id})")
    print("Look at the camera. Press SPACE to capture. Press Q to quit.\n")

    captured = False
    while not captured:
        ret, frame = cap.read()
        if not ret:
            break

        processed = preprocessor.process(frame)
        faces = detector.detect(processed)
        display = frame.copy()

        if faces:
            face = max(faces, key=lambda f: f[2] * f[3])
            x, y, w, h = face[:4]
            cv2.rectangle(display, (x, y), (x + w, y + h), (0, 255, 100), 2)
            cv2.putText(display, "Face detected — press SPACE to enroll",
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 255, 100), 2)
        else:
            cv2.putText(display, "No face detected — look at camera",
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 100, 255), 2)

        cv2.imshow("HeartShield Enrollment", display)
        key = cv2.waitKey(1) & 0xFF

        if key == ord(' ') and faces:
            face = max(faces, key=lambda f: f[2] * f[3])
            x, y, w, h = face[:4]
            face_img = processed[y:y+h, x:x+w]
            success, message = recognizer.enroll(worker_id, worker_name, face_img)
            if success:
                print(f"\n✅ {message}")
                captured = True
            else:
                print(f"\n❌ {message}")
        elif key == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

    if captured:
        print(f"\n🏆 Worker enrolled successfully!")
        print(f"   ID: {worker_id}")
        print(f"   Name: {worker_name}")
        print(f"\nNow run: python heartshield.py")

if __name__ == "__main__":
    enroll_worker()
