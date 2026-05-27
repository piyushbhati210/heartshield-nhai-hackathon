# How to Upload to GitHub — Step by Step

## Step 1 — Create GitHub Account
1. Go to https://github.com
2. Click Sign Up
3. Enter email, password, username
4. Verify your email

## Step 2 — Create New Repository
1. Click the green "New" button (top left)
2. Repository name: heartshield-nhai-hackathon
3. Description: Offline heartbeat liveness detection for NHAI Datalake 3.0
4. Select: Public
5. Check: Add a README file — NO (we have our own)
6. Click: Create repository

## Step 3 — Upload Files (Easy Method — No Git needed)

1. On your new empty repository page
2. Click "uploading an existing file" link
3. Drag and drop ALL files from this folder
4. At the bottom: write commit message = "Initial submission - HeartShield NHAI Hackathon 7.0"
5. Click "Commit changes"

## Step 4 — Upload Folders (python_core, flutter_app, web_demo, app)

GitHub web upload does NOT support folders directly.
Use this method for each folder:

1. Click "Add file" → "Create new file"
2. In the name box type: python_core/heartshield.py
3. Paste the file content
4. Commit

OR use GitHub Desktop app (easier):
1. Download: https://desktop.github.com
2. Clone your repository
3. Copy all files into the cloned folder
4. Click "Commit to main"
5. Click "Push origin"

## Step 5 — Add APK to app/ folder
1. Build APK: flutter build apk --release
2. Find it at: flutter_app/build/app/outputs/flutter-apk/app-release.apk
3. Upload to app/ folder on GitHub
4. Rename to: heartshield-release.apk

## Step 6 — Copy Your Repository Link
Your link will be:
https://github.com/YOUR_USERNAME/heartshield-nhai-hackathon

Paste this link in your NHAI submission form.

## Final GitHub Repository Should Look Like:
heartshield-nhai-hackathon/
├── README.md           ← Shows automatically on GitHub page
├── LICENSE
├── app/
│   ├── README.md
│   └── heartshield-release.apk  ← Add after building
├── python_core/
│   ├── heartshield.py
│   ├── setup_models.py
│   ├── enroll_worker.py
│   └── requirements.txt
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   └── heartshield_flutter.dart
│   ├── pubspec.yaml
│   └── android_manifest.xml
└── web_demo/
    └── HeartShield_App.html
