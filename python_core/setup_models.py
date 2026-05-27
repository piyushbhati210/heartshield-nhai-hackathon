"""
HeartShield - Model Setup Script
Run this FIRST before anything else.
Downloads all required models automatically.
"""

import os
import urllib.request
import zipfile

MODELS_DIR = "models"
os.makedirs(MODELS_DIR, exist_ok=True)

MODELS = [
    {
        "name": "Face Detection - deploy.prototxt",
        "url": "https://raw.githubusercontent.com/opencv/opencv/master/samples/dnn/face_detector/deploy.prototxt",
        "path": os.path.join(MODELS_DIR, "deploy.prototxt"),
        "size": "~4KB"
    },
    {
        "name": "Face Detection - caffemodel",
        "url": "https://github.com/opencv/opencv_3rdparty/raw/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000.caffemodel",
        "path": os.path.join(MODELS_DIR, "res10_300x300_ssd_iter_140000.caffemodel"),
        "size": "~10MB"
    },
]

def download_file(url, path, name, size):
    if os.path.exists(path):
        print(f"  ✅ Already exists: {name}")
        return True
    print(f"  ⬇️  Downloading {name} ({size})...")
    try:
        def progress(count, block_size, total_size):
            if total_size > 0:
                pct = min(100, count * block_size * 100 // total_size)
                print(f"\r     {pct}%", end="", flush=True)
        urllib.request.urlretrieve(url, path, reporthook=progress)
        print(f"\r  ✅ Downloaded: {name}          ")
        return True
    except Exception as e:
        print(f"\r  ❌ Failed: {name} — {e}")
        print(f"     Manual URL: {url}")
        return False

def check_packages():
    print("\n📦 Checking Python packages...")
    required = {
        "cv2": "opencv-python",
        "numpy": "numpy",
        "onnxruntime": "onnxruntime",
    }
    missing = []
    for module, package in required.items():
        try:
            __import__(module)
            print(f"  ✅ {package}")
        except ImportError:
            print(f"  ❌ {package} - NOT INSTALLED")
            missing.append(package)

    if missing:
        print(f"\n  Run this to install missing packages:")
        print(f"  pip install {' '.join(missing)}")
        return False
    return True

def mobilefacenet_instructions():
    """MobileFaceNet requires manual download from InsightFace"""
    model_path = os.path.join(MODELS_DIR, "mobilefacenet.onnx")
    if os.path.exists(model_path):
        print("  ✅ mobilefacenet.onnx found")
        return

    print("\n  ⚠️  MobileFaceNet ONNX model needs manual download:")
    print("  1. Go to: https://github.com/deepinsight/insightface")
    print("  2. Download: buffalo_sc (smallest model, ~100MB)")
    print("  3. Extract and copy 'w600k_mbf.onnx' to models/ folder")
    print("  4. Rename it to: mobilefacenet.onnx")
    print("\n  OR use this direct command:")
    print("  pip install insightface onnxruntime")
    print("  python -c \"import insightface; insightface.app.FaceAnalysis(name='buffalo_sc').prepare(ctx_id=-1)\"")
    print("  (Models auto-download to ~/.insightface/models/)")

if __name__ == "__main__":
    print("=" * 50)
    print("  HeartShield Setup — NHAI Hackathon 7.0")
    print("=" * 50)

    packages_ok = check_packages()

    print("\n📁 Downloading face detection models...")
    all_ok = True
    for m in MODELS:
        ok = download_file(m["url"], m["path"], m["name"], m["size"])
        if not ok:
            all_ok = False

    mobilefacenet_instructions()

    print("\n" + "=" * 50)
    if packages_ok and all_ok:
        print("✅ Setup complete! Run: python heartshield.py")
    else:
        print("⚠️  Some steps need manual action (see above)")
        print("    Complete them then run: python heartshield.py")
    print("=" * 50)
