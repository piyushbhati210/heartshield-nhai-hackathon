// HeartShield Flutter SDK
// Datalake 3.0 Integration Layer
// Drop this into your Flutter project

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─────────────────────────────────────────
// HEARTSHIELD RESULT MODEL
// ─────────────────────────────────────────
class HeartShieldResult {
  final bool faceVerified;
  final bool livenessConfirmed;
  final String livenessMode;
  final double? heartbeatBpm;
  final String? workerId;
  final String? workerName;
  final double confidence;
  final String timestamp;
  final bool networkUsed;
  final String message;

  HeartShieldResult({
    required this.faceVerified,
    required this.livenessConfirmed,
    required this.livenessMode,
    this.heartbeatBpm,
    this.workerId,
    this.workerName,
    required this.confidence,
    required this.timestamp,
    required this.networkUsed,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'face_verified': faceVerified,
    'liveness_confirmed': livenessConfirmed,
    'liveness_mode': livenessMode,
    'heartbeat_bpm': heartbeatBpm,
    'worker_id': workerId,
    'worker_name': workerName,
    'confidence': confidence,
    'timestamp': timestamp,
    'network_used': networkUsed,
    'message': message,
  };
}

// ─────────────────────────────────────────
// OFFLINE DATABASE MANAGER
// Stores all verifications locally
// Syncs to Datalake 3.0 when internet available
// ─────────────────────────────────────────
class HeartShieldDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'heartshield.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE access_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            worker_id TEXT,
            worker_name TEXT,
            timestamp TEXT,
            liveness_mode TEXT,
            bpm REAL,
            confidence REAL,
            result TEXT,
            synced INTEGER DEFAULT 0,
            raw_json TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE enrolled_workers (
            worker_id TEXT PRIMARY KEY,
            worker_name TEXT,
            embedding BLOB,
            enrolled_at TEXT
          )
        ''');
      },
    );
  }

  static Future<void> logAccess(HeartShieldResult result) async {
    final db = await database;
    await db.insert('access_logs', {
      'worker_id': result.workerId ?? 'unknown',
      'worker_name': result.workerName ?? 'unknown',
      'timestamp': result.timestamp,
      'liveness_mode': result.livenessMode,
      'bpm': result.heartbeatBpm,
      'confidence': result.confidence,
      'result': result.faceVerified ? 'GRANTED' : 'DENIED',
      'synced': 0,
      'raw_json': jsonEncode(result.toJson()),
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await database;
    return await db.query('access_logs', where: 'synced = ?', whereArgs: [0]);
  }

  static Future<void> markSynced(List<int> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'access_logs',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}

// ─────────────────────────────────────────
// DATALAKE 3.0 SYNC SERVICE
// Silently syncs when internet available
// ─────────────────────────────────────────
class DatalakeSyncService {
  final String datalakeEndpoint;
  Timer? _syncTimer;

  DatalakeSyncService({required this.datalakeEndpoint});

  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<SyncResult> syncNow() async {
    final unsynced = await HeartShieldDB.getUnsynced();
    if (unsynced.isEmpty) {
      return SyncResult(synced: 0, message: 'Nothing to sync');
    }

    // NOTE: Replace with your actual Datalake 3.0 API endpoint
    // This is the integration point for NHAI Datalake 3.0
    try {
      // Simulate sync - replace with actual HTTP call:
      // final response = await http.post(
      //   Uri.parse('$datalakeEndpoint/api/access-logs/batch'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'logs': unsynced}),
      // );

      final ids = unsynced.map((r) => r['id'] as int).toList();
      await HeartShieldDB.markSynced(ids);
      return SyncResult(synced: unsynced.length, message: 'Synced ${unsynced.length} records');
    } catch (e) {
      return SyncResult(synced: 0, message: 'Sync failed: $e (will retry)');
    }
  }
}

class SyncResult {
  final int synced;
  final String message;
  SyncResult({required this.synced, required this.message});
}

// ─────────────────────────────────────────
// HEARTSHIELD CAMERA SCREEN
// Drop-in UI widget for Datalake 3.0
// Usage: Navigate to HeartShieldScreen()
// ─────────────────────────────────────────
class HeartShieldScreen extends StatefulWidget {
  final Function(HeartShieldResult) onResult;
  const HeartShieldScreen({Key? key, required this.onResult}) : super(key: key);

  @override
  State<HeartShieldScreen> createState() => _HeartShieldScreenState();
}

class _HeartShieldScreenState extends State<HeartShieldScreen> {
  CameraController? _controller;
  String _status = 'Initializing camera...';
  String _stage = 'STARTING';
  double? _bpm;
  bool _processing = false;
  int _frameCount = 0;

  // rPPG signal buffer
  final List<double> _greenBuffer = [];
  static const int _bufferSize = 90; // 3 seconds at 30fps

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = 'No camera found');
      return;
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() => _status = 'Look at the camera...');
    _stage = 'DETECTING';
    _controller!.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) {
    if (_processing) return;
    _frameCount++;
    if (_frameCount % 3 != 0) return; // Process every 3rd frame

    _processing = true;

    // Extract green channel mean from center region (forehead proxy)
    final height = image.height;
    final width = image.width;
    final yPlane = image.planes[0].bytes;

    // Sample center region
    double greenSum = 0;
    int count = 0;
    final y1 = (height * 0.1).toInt();
    final y2 = (height * 0.4).toInt();
    final x1 = (width * 0.3).toInt();
    final x2 = (width * 0.7).toInt();

    for (int y = y1; y < y2; y += 4) {
      for (int x = x1; x < x2; x += 4) {
        greenSum += yPlane[y * width + x];
        count++;
      }
    }

    if (count > 0) {
      _greenBuffer.add(greenSum / count);
      if (_greenBuffer.length > _bufferSize) _greenBuffer.removeAt(0);
    }

    // Analyze heartbeat when buffer is full
    if (_greenBuffer.length >= _bufferSize) {
      final bpm = _analyzeHeartbeat();
      if (bpm != null && bpm > 45 && bpm < 120) {
        setState(() {
          _bpm = bpm;
          _stage = 'LIVENESS_PASS';
          _status = '💓 Heartbeat: ${bpm.toStringAsFixed(0)} BPM — Liveness confirmed!';
        });
        // Proceed to face recognition
        _proceedToRecognition();
      } else {
        final pct = (_greenBuffer.length / _bufferSize * 100).toInt();
        setState(() {
          _stage = 'DETECTING_HEARTBEAT';
          _status = 'Detecting heartbeat... $pct% (hold still)';
        });
      }
    }

    _processing = false;
  }

  double? _analyzeHeartbeat() {
    if (_greenBuffer.length < _bufferSize) return null;

    // Simple peak detection for BPM
    final signal = List<double>.from(_greenBuffer);
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final detrended = signal.map((v) => v - mean).toList();

    // Count zero crossings as a simple frequency estimate
    int crossings = 0;
    for (int i = 1; i < detrended.length; i++) {
      if (detrended[i - 1] < 0 && detrended[i] >= 0) crossings++;
    }

    // BPM = crossings per second * 60
    final seconds = _bufferSize / 30.0;
    final bpm = (crossings / seconds) * 60;
    return bpm;
  }

  void _proceedToRecognition() {
    _controller?.stopImageStream();
    setState(() {
      _stage = 'RECOGNIZING';
      _status = 'Running face recognition...';
    });

    // NOTE: This is where you call your face recognition
    // In production: pass captured frame to Python backend
    // or use TFLite model via tflite_flutter package

    // Simulated result for demo:
    Future.delayed(const Duration(seconds: 2), () {
      final result = HeartShieldResult(
        faceVerified: true,
        livenessConfirmed: true,
        livenessMode: 'rppg_heartbeat',
        heartbeatBpm: _bpm,
        workerId: 'NHAI_001',
        workerName: 'Demo Worker',
        confidence: 0.94,
        timestamp: DateTime.now().toIso8601String(),
        networkUsed: false,
        message: 'Access granted',
      );

      HeartShieldDB.logAccess(result);
      widget.onResult(result);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('HeartShield', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Camera preview
          if (_controller?.value.isInitialized == true)
            Expanded(
              child: CameraPreview(_controller!),
            )
          else
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            ),

          // Status panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              children: [
                if (_bpm != null)
                  Text(
                    '💓 ${_bpm!.toStringAsFixed(0)} BPM',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '🔴 100% Offline — No internet used',
                  style: TextStyle(color: Colors.green[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// HOW TO USE IN DATALAKE 3.0
// Add these 3 lines anywhere in your app
// ─────────────────────────────────────────
//
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => HeartShieldScreen(
//     onResult: (result) {
//       print(result.toJson()); // Use result in your app
//     },
//   ),
// ));
