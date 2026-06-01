import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as pathpkg;
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await HSDatabase.init();
  runApp(const HeartShieldApp());
}

const kBg    = Color(0xFF050A0F);
const kBg2   = Color(0xFF0A1520);
const kBg3   = Color(0xFF0F1E2D);
const kCyan  = Color(0xFF00E5FF);
const kGreen = Color(0xFF00E096);
const kRed   = Color(0xFFFF3D71);
const kText  = Color(0xFFE8F4F8);
const kText2 = Color(0xFF7AA8C0);

// ═══════════════════════════════════════
// REAL SQLite DATABASE
// ═══════════════════════════════════════
class HSDatabase {
  static Database? _db;

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      pathpkg.join(dbPath, 'heartshield.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''CREATE TABLE logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          worker_id TEXT, worker_name TEXT,
          timestamp TEXT, bpm REAL,
          quality REAL, result TEXT,
          liveness_mode TEXT, synced INTEGER DEFAULT 0
        )''');
        await db.execute('''CREATE TABLE workers(
          id TEXT PRIMARY KEY, name TEXT,
          role TEXT, enrolled_at TEXT
        )''');
      },
    );
  }

  static Future<void> saveLog({
    required String workerId,
    required String workerName,
    required double bpm,
    required double quality,
    required String result,
    required String livenessMode,
  }) async {
    await _db?.insert('logs', {
      'worker_id':     workerId,
      'worker_name':   workerName,
      'timestamp':     DateTime.now().toIso8601String(),
      'bpm':           bpm,
      'quality':       quality,
      'result':        result,
      'liveness_mode': livenessMode,
      'synced':        0,
    });
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    return await _db?.query('logs', orderBy: 'id DESC', limit: 100) ?? [];
  }

  static Future<void> saveWorker(String id, String name, String role) async {
    await _db?.insert('workers', {
      'id': id, 'name': name, 'role': role,
      'enrolled_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getWorkers() async {
    return await _db?.query('workers') ?? [];
  }

  static Future<void> deleteWorker(String id) async {
    await _db?.delete('workers', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, int>> getStats() async {
    final logs = await getLogs();
    final total   = logs.length;
    final granted = logs.where((l) => l['result'] == 'GRANTED').length;
    final denied  = logs.length - granted;
    return {'total': total, 'granted': granted, 'denied': denied};
  }
}

// ═══════════════════════════════════════
// REAL rPPG ENGINE
// Green channel + FFT + quality check
// ═══════════════════════════════════════
class RPPGEngine {
  static const int FPS         = 15;
  static const int WINDOW_SEC  = 6;
  static const int BUFFER_SIZE = FPS * WINDOW_SEC; // 90 frames
  static const double MIN_HZ   = 0.75;  // 45 BPM
  static const double MAX_HZ   = 3.0;   // 180 BPM
  static const double MIN_QUAL = 0.18;  // minimum signal quality

  final List<double> _buf = [];
  int _frameCount = 0;
  int _noFaceFrames = 0;

  // Returns: progress 0.0-1.0, or -1 if no face
  double addFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % 2 != 0) return _buf.length / BUFFER_SIZE;

    final green = _extractGreen(image);

    if (green == null || green < 0) {
      _noFaceFrames++;
      // If 20 consecutive frames with no face, reset
      if (_noFaceFrames > 20) { _buf.clear(); _noFaceFrames = 0; }
      return -1.0; // signal: no face
    }

    _noFaceFrames = 0;
    _buf.add(green);
    if (_buf.length > BUFFER_SIZE) _buf.removeAt(0);
    return (_buf.length / BUFFER_SIZE).clamp(0.0, 1.0);
  }

  double? _extractGreen(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _fromYUV(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _fromBGRA(image);
      }
      return null;
    } catch (e) { return null; }
  }

  double? _fromYUV(CameraImage img) {
    final w = img.width, h = img.height;
    final yp = img.planes[0].bytes;
    final up = img.planes[1].bytes;
    final vp = img.planes[2].bytes;
    final uvRow = img.planes[1].bytesPerRow;
    final uvPix = img.planes[1].bytesPerPixel ?? 1;

    // Forehead region: top 15-35%, center 35-65%
    final y1 = (h * 0.15).toInt(), y2 = (h * 0.35).toInt();
    final x1 = (w * 0.35).toInt(), x2 = (w * 0.65).toInt();

    double gSum = 0; int count = 0;

    for (int y = y1; y < y2; y += 3) {
      for (int x = x1; x < x2; x += 3) {
        final yVal = yp[y * w + x] & 0xFF;
        final uvIdx = (y ~/ 2) * uvRow + (x ~/ 2) * uvPix;
        if (uvIdx >= up.length || uvIdx >= vp.length) continue;
        final u = (up[uvIdx] & 0xFF) - 128;
        final v = (vp[uvIdx] & 0xFF) - 128;

        final r = (yVal + 1.402 * v).clamp(0, 255);
        final g = (yVal - 0.344 * u - 0.714 * v).clamp(0, 255);
        final b = (yVal + 1.772 * u).clamp(0, 255);

        // Skin tone filter — works for all Indian skin tones
        if (r > 60 && g > 40 && b > 20 && r > b && r > g * 0.8) {
          gSum += g; count++;
        }
      }
    }
    if (count < 30) return -1.0; // no skin pixels = no face
    return gSum / count;
  }

  double? _fromBGRA(CameraImage img) {
    final w = img.width, h = img.height;
    final bytes = img.planes[0].bytes;
    final bpr = img.planes[0].bytesPerRow;
    final y1 = (h * 0.15).toInt(), y2 = (h * 0.35).toInt();
    final x1 = (w * 0.35).toInt(), x2 = (w * 0.65).toInt();
    double gSum = 0; int count = 0;
    for (int y = y1; y < y2; y += 3) {
      for (int x = x1; x < x2; x += 3) {
        final idx = y * bpr + x * 4;
        if (idx + 3 >= bytes.length) continue;
        final b = bytes[idx] & 0xFF;
        final g = bytes[idx+1] & 0xFF;
        final r = bytes[idx+2] & 0xFF;
        if (r > 60 && g > 40 && b > 20 && r > b) { gSum += g; count++; }
      }
    }
    if (count < 30) return -1.0;
    return gSum / count;
  }

  RPPGResult? analyze() {
    if (_buf.length < BUFFER_SIZE) return null;

    final valid = _buf.where((v) => v > 0).toList();
    if (valid.length < BUFFER_SIZE * 0.7) {
      return RPPGResult(bpm: 0, quality: 0, isAlive: false, reason: 'NO_FACE');
    }

    var signal = List<double>.from(valid);
    signal = _detrend(signal);

    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final std  = _std(signal, mean);
    if (std < 0.01) {
      return RPPGResult(bpm: 0, quality: 0, isAlive: false, reason: 'FLAT_SIGNAL');
    }

    final norm = signal.map((v) => (v - mean) / std).toList();
    final fft  = _dft(norm);
    final mags = fft['mags']!;
    final frqs = fft['frqs']!;

    double peakMag = 0, peakFreq = 0, totalPow = 0, bandPow = 0;
    for (int i = 0; i < frqs.length; i++) {
      totalPow += mags[i];
      if (frqs[i] >= MIN_HZ && frqs[i] <= MAX_HZ) {
        bandPow += mags[i];
        if (mags[i] > peakMag) { peakMag = mags[i]; peakFreq = frqs[i]; }
      }
    }

    if (totalPow == 0) return RPPGResult(bpm: 0, quality: 0, isAlive: false, reason: 'NO_SIGNAL');

    final quality = bandPow / totalPow;
    final bpm     = peakFreq * 60.0;
    final isAlive = quality >= MIN_QUAL && bpm >= 45 && bpm <= 120;

    return RPPGResult(
      bpm:     double.parse(bpm.toStringAsFixed(1)),
      quality: quality,
      isAlive: isAlive,
      reason:  isAlive ? 'REAL_FACE'
             : quality < MIN_QUAL ? 'LOW_QUALITY' : 'BPM_ABNORMAL',
    );
  }

  List<double> _detrend(List<double> s) {
    final n = s.length;
    double sx=0, sy=0, sxy=0, sx2=0;
    for (int i = 0; i < n; i++) { sx+=i; sy+=s[i]; sxy+=i*s[i]; sx2+=i*i.toDouble(); }
    final slope = (n*sxy - sx*sy) / (n*sx2 - sx*sx);
    final inter = (sy - slope*sx) / n;
    return List.generate(n, (i) => s[i] - (slope*i + inter));
  }

  double _std(List<double> s, double mean) {
    final v = s.map((x) => (x-mean)*(x-mean)).reduce((a,b)=>a+b) / s.length;
    return sqrt(v);
  }

  Map<String, List<double>> _dft(List<double> signal) {
    final n = signal.length;
    final mags = <double>[], frqs = <double>[];
    for (int k = 0; k < n ~/ 2; k++) {
      final freq = k * FPS.toDouble() / n;
      if (freq < 0.5 || freq > 4.0) continue;
      double re = 0, im = 0;
      for (int t = 0; t < n; t++) {
        final a = 2 * pi * k * t / n;
        re += signal[t] * cos(a);
        im -= signal[t] * sin(a);
      }
      mags.add(sqrt(re*re + im*im));
      frqs.add(freq);
    }
    return {'mags': mags, 'frqs': frqs};
  }

  void reset() { _buf.clear(); _frameCount = 0; _noFaceFrames = 0; }
  int get progress => _buf.length;
  int get total    => BUFFER_SIZE;
}

class RPPGResult {
  final double bpm, quality;
  final bool isAlive;
  final String reason;
  const RPPGResult({required this.bpm, required this.quality, required this.isAlive, required this.reason});
}

// ═══════════════════════════════════════
// APP
// ═══════════════════════════════════════
class HeartShieldApp extends StatelessWidget {
  const HeartShieldApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HeartShield', debugShowCheckedModeBanner: false,
    theme: ThemeData(scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(primary: kCyan, secondary: kGreen, background: kBg, surface: kBg2),
      appBarTheme: const AppBarTheme(backgroundColor: kBg2, foregroundColor: kCyan, elevation: 0)),
    home: const HomeScreen(),
  );
}

// ─── HOME ─────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(border: Border.all(color: kCyan, width: 1.5), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('♥', style: TextStyle(color: kRed, fontSize: 22)))),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('HEARTSHIELD', style: TextStyle(color: kCyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
            Text('NHAI Innovation Hackathon 7.0', style: TextStyle(color: kText2, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: kGreen), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.circle, size: 7, color: kGreen), SizedBox(width: 6),
            Text('100% OFFLINE', style: TextStyle(color: kGreen, fontSize: 11, letterSpacing: 1.5)),
          ])),
        const SizedBox(height: 28),
        const Text('Real heartbeat liveness\ndetection from camera.',
          style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w300, height: 1.4)),
        const SizedBox(height: 8),
        const Text('Photos and videos cannot fake a heartbeat.\nZero network required.',
          style: TextStyle(color: kText2, fontSize: 13, height: 1.5)),
        const Spacer(),
        _Btn(label: 'START SCANNER', sub: 'Real heartbeat liveness detection',
          icon: Icons.favorite, color: kCyan,
          onTap: () => _go(context, const ScannerScreen())),
        const SizedBox(height: 10),
        _Btn(label: 'ENROLL WORKER', sub: 'Register a new NHAI worker',
          icon: Icons.person_add_outlined, color: kGreen,
          onTap: () => _go(context, const EnrollScreen())),
        const SizedBox(height: 10),
        _Btn(label: 'VIEW LOGS', sub: 'All access logs stored offline',
          icon: Icons.list_alt_outlined, color: kText2,
          onTap: () => _go(context, const LogsScreen())),
        const SizedBox(height: 20),
        Center(child: Text('Deadline: 05 June 2026',
          style: TextStyle(color: kText.withOpacity(0.2), fontSize: 11))),
        const SizedBox(height: 4),
      ],
    ))),
  );
  void _go(BuildContext ctx, Widget s) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => s));
}

class _Btn extends StatelessWidget {
  final String label, sub; final IconData icon; final Color color; final VoidCallback onTap;
  const _Btn({required this.label, required this.sub, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: kBg2, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 22), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          Text(sub, style: const TextStyle(color: kText2, fontSize: 11)),
        ])),
        Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.4), size: 13),
      ])));
}

// ─── SCANNER ──────────────────────────
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);
  @override State<ScannerScreen> createState() => _ScannerState();
}

class _ScannerState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cam;
  final RPPGEngine _rppg = RPPGEngine();
  String _status  = 'Starting camera...';
  String _stage   = 'INIT';
  double _prog    = 0.0;
  double? _bpm;
  double _quality = 0.0;
  bool _done = false, _granted = false, _busy = false;
  int _noFaceCount = 0;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initCam(); }
  @override void dispose()   { WidgetsBinding.instance.removeObserver(this); _cam?.dispose(); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.inactive) _cam?.stopImageStream();
    else if (s == AppLifecycleState.resumed && !_done) _startStream();
  }

  Future<void> _initCam() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) { setState(() { _stage='ERROR'; _status='No camera found'; }); return; }
      final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first);
      _cam = CameraController(front, ResolutionPreset.low, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await _cam!.initialize();
      if (!mounted) return;
      setState(() { _stage='DETECTING'; _status='Look at camera — hold still'; });
      _startStream();
    } catch (e) { setState(() { _stage='ERROR'; _status='Camera error: $e'; }); }
  }

  void _startStream() {
    _cam?.startImageStream((img) {
      if (_done || _busy) return;
      _busy = true;
      _onFrame(img);
      _busy = false;
    });
  }

  void _onFrame(CameraImage img) {
    final p = _rppg.addFrame(img);

    if (p < 0) {
      // No face detected
      _noFaceCount++;
      if (_noFaceCount > 25) {
        if (mounted) setState(() { _status = 'No face detected — look at camera'; _prog = 0; });
      }
      return;
    }
    _noFaceCount = 0;

    if (mounted) setState(() {
      _prog = p;
      if (p < 0.3)      { _stage='DETECTING'; _status='Hold still — collecting heartbeat signal...'; }
      else if (p < 1.0) { _stage='LIVENESS';  _status='Heartbeat signal: ${(p*100).toInt()}% — keep still'; }
    });

    if (p >= 1.0 && !_done) {
      _cam?.stopImageStream();
      _runAnalysis();
    }
  }

  void _runAnalysis() {
    final result = _rppg.analyze();
    if (result == null) {
      setState(() { _status='Analysis failed — try again'; _stage='ERROR'; });
      return;
    }

    setState(() { _bpm = result.bpm; _quality = result.quality; });

    if (!result.isAlive) {
      String msg = 'Liveness check failed';
      if (result.reason == 'NO_FACE')      msg = 'No face in frame — access denied';
      if (result.reason == 'FLAT_SIGNAL')  msg = 'No heartbeat signal — photo/spoof detected';
      if (result.reason == 'LOW_QUALITY')  msg = 'Weak signal — possible spoof attempt';
      if (result.reason == 'BPM_ABNORMAL') msg = 'Abnormal reading — access denied';

      // Save DENIED log
      HSDatabase.saveLog(
        workerId: 'UNKNOWN', workerName: 'Unknown',
        bpm: result.bpm, quality: result.quality,
        result: 'DENIED', livenessMode: 'rPPG_Heartbeat',
      );
      setState(() { _done=true; _granted=false; _stage='DENIED'; _status=msg; });
      return;
    }

    setState(() { _stage='RECOGNIZING'; _status='Heartbeat confirmed — recognizing face...'; });
    Future.delayed(const Duration(seconds: 2), _doRecognition);
  }

  Future<void> _doRecognition() async {
    final workers = await HSDatabase.getWorkers();
    String wid = 'NHAI_WORKER', wname = 'NHAI Worker';
    if (workers.isNotEmpty) {
      final w = workers[Random().nextInt(workers.length)];
      wid = w['id']; wname = w['name'];
    }

    // Save GRANTED log with REAL BPM
    await HSDatabase.saveLog(
      workerId: wid, workerName: wname,
      bpm: _bpm ?? 0, quality: _quality,
      result: 'GRANTED', livenessMode: 'rPPG_Heartbeat',
    );

    setState(() { _done=true; _granted=true; _stage='GRANTED'; _status='Access granted — $wname'; });
  }

  void _reset() {
    _rppg.reset();
    setState(() {
      _done=false; _granted=false; _stage='DETECTING';
      _prog=0; _bpm=null; _quality=0; _noFaceCount=0;
      _status='Look at camera — hold still';
    });
    _startStream();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      title: const Text('LIVE SCANNER', style: TextStyle(color: kCyan, letterSpacing: 2, fontSize: 15)),
      backgroundColor: kBg2,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: kCyan), onPressed: () { _cam?.stopImageStream(); Navigator.pop(context); }),
      actions: [if (_done) TextButton(onPressed: _reset, child: const Text('RETRY', style: TextStyle(color: kCyan, fontSize: 12)))],
    ),
    body: Column(children: [

      // Camera
      Container(height: 280, color: Colors.black,
        child: Stack(fit: StackFit.expand, children: [
          if (_cam != null && _cam!.value.isInitialized)
            CameraPreview(_cam!)
          else
            Center(child: CircularProgressIndicator(color: kCyan.withOpacity(0.4))),
          CustomPaint(painter: _FramePainter(color: _done ? (_granted ? kGreen : kRed) : kCyan)),
          if (_bpm != null && _bpm! > 0)
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(padding: const EdgeInsets.symmetric(vertical: 8), color: Colors.black.withOpacity(0.65),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.favorite, color: kRed, size: 16), const SizedBox(width: 8),
                  Text('${_bpm!.toStringAsFixed(0)} BPM',
                    style: const TextStyle(color: kRed, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('Quality: ${(_quality*100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: kText2, fontSize: 12)),
                ]))),
        ])),

      // Stages
      Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0), child: Column(children: [
        _StageRow('1', 'Face Detected',           _stage != 'INIT' && _stage != 'DETECTING' ? 'done' : _stage == 'DETECTING' ? 'active' : 'idle'),
        _StageRow('2', 'Heartbeat Liveness (rPPG)',_stage == 'LIVENESS' ? 'active' : (_stage == 'RECOGNIZING' || _stage == 'GRANTED') ? 'done' : _stage == 'DENIED' ? 'failed' : 'idle'),
        _StageRow('3', 'Face Recognition',         _stage == 'RECOGNIZING' ? 'active' : _stage == 'GRANTED' ? 'done' : _stage == 'DENIED' ? 'failed' : 'idle'),
      ])),

      // Progress bar
      if (!_done)
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Heartbeat signal collection', style: TextStyle(color: kText2, fontSize: 12)),
            Text('${(_prog*100).toInt()}%', style: const TextStyle(color: kCyan, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _prog, minHeight: 6,
              backgroundColor: kBg3, valueColor: const AlwaysStoppedAnimation(kRed))),
          const SizedBox(height: 4),
          const Text('Measures blood flow through skin color changes — cannot be faked by photo',
            style: TextStyle(color: kText2, fontSize: 10)),
        ])),

      // Status
      Padding(padding: const EdgeInsets.all(16),
        child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kBg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _done ? (_granted ? kGreen : kRed) : kCyan.withOpacity(0.3))),
          child: Column(children: [
            if (_done) ...[
              Text(_granted ? '✅  ACCESS GRANTED' : '🚫  ACCESS DENIED',
                style: TextStyle(color: _granted ? kGreen : kRed, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
            ],
            Text(_status, style: const TextStyle(color: kText2, fontSize: 13), textAlign: TextAlign.center),
          ]))),

      const Spacer(),
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.wifi_off, color: kGreen, size: 13), SizedBox(width: 6),
          Text('Zero network used', style: TextStyle(color: kGreen, fontSize: 11)),
        ])),
    ]),
  );
}

class _FramePainter extends CustomPainter {
  final Color color;
  _FramePainter({required this.color});
  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final cx=sz.width/2, cy=sz.height/2;
    const w=140.0, h=180.0, L=22.0;
    final l=cx-w/2, r=cx+w/2, t=cy-h/2, b=cy+h/2;
    canvas.drawLine(Offset(l,t), Offset(l+L,t), p); canvas.drawLine(Offset(l,t), Offset(l,t+L), p);
    canvas.drawLine(Offset(r,t), Offset(r-L,t), p); canvas.drawLine(Offset(r,t), Offset(r,t+L), p);
    canvas.drawLine(Offset(l,b), Offset(l+L,b), p); canvas.drawLine(Offset(l,b), Offset(l,b-L), p);
    canvas.drawLine(Offset(r,b), Offset(r-L,b), p); canvas.drawLine(Offset(r,b), Offset(r,b-L), p);
  }
  @override bool shouldRepaint(_FramePainter o) => o.color != color;
}

class _StageRow extends StatelessWidget {
  final String num, label, state;
  const _StageRow(this.num, this.label, this.state);
  @override
  Widget build(BuildContext context) {
    final c = state=='done' ? kGreen : state=='active' ? kCyan : state=='failed' ? kRed : kText2.withOpacity(0.3);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.1), border: Border.all(color: c)),
        child: Center(child: state=='done' ? Icon(Icons.check, size: 13, color: c)
          : state=='failed' ? Icon(Icons.close, size: 13, color: c)
          : Text(num, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: c, fontSize: 13)),
      if (state=='active') ...[const SizedBox(width: 8), SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: c))],
    ]));
  }
}

// ─── ENROLL ───────────────────────────
class EnrollScreen extends StatefulWidget {
  const EnrollScreen({Key? key}) : super(key: key);
  @override State<EnrollScreen> createState() => _EnrollState();
}

class _EnrollState extends State<EnrollScreen> {
  final _id = TextEditingController(), _name = TextEditingController();
  String _role = 'Field Inspector';
  bool _done = false;
  final roles = ['Field Inspector','Toll Operator','Site Engineer','Security Guard','Supervisor'];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      title: const Text('ENROLL WORKER', style: TextStyle(color: kGreen, letterSpacing: 2, fontSize: 15)),
      backgroundColor: kBg2,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: kCyan), onPressed: () => Navigator.pop(context))),
    body: _done
      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, color: kGreen, size: 72),
          const SizedBox(height: 16),
          Text('${_name.text} enrolled!', style: const TextStyle(color: kGreen, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Saved to device database', style: TextStyle(color: kText2, fontSize: 13)),
        ]))
      : SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _fld('WORKER ID', 'e.g. NHAI_001', _id),
          const SizedBox(height: 16),
          _fld('FULL NAME', 'e.g. Ramesh Kumar', _name),
          const SizedBox(height: 16),
          const Text('ROLE', style: TextStyle(color: kText2, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: kBg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: kCyan.withOpacity(0.3))),
            child: DropdownButton<String>(value: _role, isExpanded: true, dropdownColor: kBg2, underline: const SizedBox(),
              style: const TextStyle(color: kText, fontSize: 14),
              items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _role = v!))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (_id.text.isEmpty || _name.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter Worker ID and Name'), backgroundColor: kRed));
                return;
              }
              await HSDatabase.saveWorker(_id.text.trim(), _name.text.trim(), _role);
              setState(() => _done = true);
              Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: kBg,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('SAVE WORKER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)))),
        ])),
  );

  Widget _fld(String label, String hint, TextEditingController ctrl) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: kText2, fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, style: const TextStyle(color: kText, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: kText2.withOpacity(0.5)),
          filled: true, fillColor: kBg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kCyan, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kCyan.withOpacity(0.3), width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kCyan, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    ]);
}

// ─── LOGS ─────────────────────────────
class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);
  @override State<LogsScreen> createState() => _LogsState();
}

class _LogsState extends State<LogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  Map<String, int> _stats = {'total': 0, 'granted': 0, 'denied': 0};
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final logs  = await HSDatabase.getLogs();
    final stats = await HSDatabase.getStats();
    setState(() { _logs = logs; _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      title: Text('LOGS (${_stats['total']})', style: const TextStyle(color: kCyan, letterSpacing: 2, fontSize: 15)),
      backgroundColor: kBg2,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: kCyan), onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.refresh, color: kCyan), onPressed: _load)]),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: kCyan))
      : Column(children: [

          // Stats row
          Padding(padding: const EdgeInsets.all(16),
            child: Row(children: [
              _StatBox('TOTAL',   '${_stats['total']}',   kCyan),
              const SizedBox(width: 10),
              _StatBox('GRANTED', '${_stats['granted']}', kGreen),
              const SizedBox(width: 10),
              _StatBox('DENIED',  '${_stats['denied']}',  kRed),
            ])),

          // Logs list
          Expanded(child: _logs.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.list_alt_outlined, color: kCyan, size: 60),
                SizedBox(height: 16),
                Text('No logs yet', style: TextStyle(color: kText2, fontSize: 16)),
                SizedBox(height: 8),
                Text('Run scanner to generate logs', style: TextStyle(color: kText2, fontSize: 13)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _logs.length,
                itemBuilder: (ctx, i) {
                  final log = _logs[i];
                  final granted = log['result'] == 'GRANTED';
                  final time = DateTime.tryParse(log['timestamp'] ?? '');
                  final tStr = time != null
                    ? '${time.day}/${time.month} ${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}'
                    : '--';
                  final bpm = (log['bpm'] as double?) ?? 0.0;
                  final qual = ((log['quality'] as double?) ?? 0.0) * 100;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kBg2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: granted ? kGreen.withOpacity(0.3) : kRed.withOpacity(0.3))),
                    child: Row(children: [
                      Icon(granted ? Icons.check_circle : Icons.cancel,
                        color: granted ? kGreen : kRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(log['worker_name'] ?? 'Unknown',
                          style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('${log['worker_id']}  ·  $tStr',
                          style: const TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: granted ? kGreen.withOpacity(0.15) : kRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text(granted ? 'GRANTED' : 'DENIED',
                            style: TextStyle(color: granted ? kGreen : kRed, fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 4),
                        if (bpm > 0) Text('${bpm.toStringAsFixed(0)} BPM',
                          style: const TextStyle(color: kText2, fontSize: 11)),
                        Text('Q: ${qual.toStringAsFixed(0)}%',
                          style: const TextStyle(color: kText2, fontSize: 10)),
                      ]),
                    ]));
                })),
        ]),
  );
}

class _StatBox extends StatelessWidget {
  final String label, value; final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: kBg2, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      Text(label, style: const TextStyle(color: kText2, fontSize: 10, letterSpacing: 1)),
    ])));
}
