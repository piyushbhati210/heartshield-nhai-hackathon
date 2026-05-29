import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'heartshield_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HeartShieldApp());
}

class HeartShieldApp extends StatelessWidget {
  const HeartShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF050A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00E096),
          error: Color(0xFFFF3D71),
          background: Color(0xFF050A0F),
          surface: Color(0xFF0A1520),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1520),
          foregroundColor: Color(0xFF00E5FF),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE8F4F8)),
          bodyMedium: TextStyle(color: Color(0xFFE8F4F8)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo + Title
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('♥', style: TextStyle(color: Color(0xFFFF3D71), fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('HEARTSHIELD',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 24,
                        fontWeight: FontWeight.bold, letterSpacing: 3)),
                  Text('NHAI Innovation Hackathon 7.0',
                    style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11, letterSpacing: 1)),
                ]),
              ]),

              const SizedBox(height: 32),

              // Offline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E096)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.circle, size: 8, color: Color(0xFF00E096)),
                  SizedBox(width: 6),
                  Text('100% OFFLINE', style: TextStyle(color: Color(0xFF00E096),
                      fontSize: 12, letterSpacing: 1.5)),
                ]),
              ),

              const SizedBox(height: 32),

              const Text('Offline facial recognition\nwith heartbeat liveness detection.',
                style: TextStyle(color: Color(0xFFE8F4F8), fontSize: 22,
                    fontWeight: FontWeight.w300, height: 1.4)),

              const SizedBox(height: 12),

              const Text(
                'Works in zero-network zones.\nBuilt for NHAI Datalake 3.0.',
                style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 15, height: 1.5),
              ),

              const Spacer(),

              // START SCANNER button — goes directly to scanner, no popup
              _ActionButton(
                label: 'START SCANNER',
                subtitle: 'Scan face with heartbeat detection',
                icon: Icons.face_retouching_natural,
                color: const Color(0xFF00E5FF),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => HeartShieldScreen(
                    onResult: (result) {
                      Navigator.pop(context);
                      _showResult(context, result);
                    },
                  ),
                )),
              ),

              const SizedBox(height: 12),

              // ENROLL WORKER — shows info then navigates
              _ActionButton(
                label: 'ENROLL WORKER',
                subtitle: 'Register a new NHAI worker',
                icon: Icons.person_add_outlined,
                color: const Color(0xFF00E096),
                onTap: () => _showEnrollInfo(context),
              ),

              const SizedBox(height: 12),

              // VIEW LOGS — shows log screen
              _ActionButton(
                label: 'VIEW LOGS',
                subtitle: 'Access logs stored offline',
                icon: Icons.list_alt_outlined,
                color: const Color(0xFF7AA8C0),
                onTap: () => _showLogsScreen(context),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Submission Deadline: 05 June 2026',
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showResult(BuildContext context, HeartShieldResult result) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A1520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: result.faceVerified
                ? const Color(0xFF00E096)
                : const Color(0xFFFF3D71),
          ),
        ),
        title: Text(
          result.faceVerified ? '✅ ACCESS GRANTED' : '🚫 ACCESS DENIED',
          style: TextStyle(
            color: result.faceVerified
                ? const Color(0xFF00E096)
                : const Color(0xFFFF3D71),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (result.workerName != null)
            Text(result.workerName!,
                style: const TextStyle(color: Color(0xFFE8F4F8), fontSize: 16)),
          const SizedBox(height: 8),
          if (result.heartbeatBpm != null)
            Text('Heartbeat: ${result.heartbeatBpm!.toStringAsFixed(0)} BPM',
                style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
          Text('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E096).withOpacity(0.5)),
            ),
            child: const Text('Network used: NONE',
                style: TextStyle(color: Color(0xFF00E096), fontSize: 11)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _showEnrollInfo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFF050A0F),
        appBar: AppBar(
          title: const Text('ENROLL WORKER',
              style: TextStyle(color: Color(0xFF00E096), letterSpacing: 2)),
          backgroundColor: const Color(0xFF0A1520),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E096).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0A1520),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('HOW TO ENROLL WORKERS',
                      style: TextStyle(color: Color(0xFF00E096), fontSize: 13,
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                  SizedBox(height: 16),
                  Text('Step 1',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('On your laptop, run:\npython enroll_worker.py',
                      style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6)),
                  SizedBox(height: 12),
                  Text('Step 2',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Enter Worker ID and Name',
                      style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6)),
                  SizedBox(height: 12),
                  Text('Step 3',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Look at webcam and press SPACE to capture face',
                      style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6)),
                  SizedBox(height: 12),
                  Text('Step 4',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Face data syncs to app automatically when connected',
                      style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6)),
                ]),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void _showLogsScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFF050A0F),
        appBar: AppBar(
          title: const Text('ACCESS LOGS',
              style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 2)),
          backgroundColor: const Color(0xFF0A1520),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.list_alt_outlined, color: Color(0xFF00E5FF), size: 64),
              const SizedBox(height: 16),
              const Text('All logs stored offline',
                  style: TextStyle(color: Color(0xFFE8F4F8), fontSize: 16)),
              const SizedBox(height: 8),
              const Text('SQLite database on device',
                  style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
              const SizedBox(height: 8),
              const Text('Syncs to NHAI Datalake 3.0\nwhen internet is available',
                  style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E096)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('● 100% OFFLINE',
                    style: TextStyle(color: Color(0xFF00E096), fontSize: 12, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.subtitle, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1520),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
  }
}