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

              const SizedBox(height: 48),

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

              // Main action buttons
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

              _ActionButton(
                label: 'ENROLL WORKER',
                subtitle: 'Register a new NHAI worker',
                icon: Icons.person_add_outlined,
                color: const Color(0xFF00E096),
                onTap: () => _showEnrollDialog(context),
              ),

              const SizedBox(height: 12),

              _ActionButton(
                label: 'VIEW LOGS',
                subtitle: 'Access logs stored offline',
                icon: Icons.list_alt_outlined,
                color: const Color(0xFF7AA8C0),
                onTap: () => _showLogsInfo(context),
              ),

              const SizedBox(height: 24),

              // Footer
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
          result.faceVerified ? 'ACCESS GRANTED' : 'ACCESS DENIED',
          style: TextStyle(
            color: result.faceVerified
                ? const Color(0xFF00E096)
                : const Color(0xFFFF3D71),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(result.faceVerified ? '✅' : '🚫', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          if (result.workerName != null)
            Text(result.workerName!,
                style: const TextStyle(color: Color(0xFFE8F4F8), fontSize: 16)),
          if (result.heartbeatBpm != null)
            Text('Heartbeat: ${result.heartbeatBpm!.toStringAsFixed(0)} BPM',
                style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
          Text('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
          const SizedBox(height: 8),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _showEnrollDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A1520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E096)),
        ),
        title: const Text('Enroll Worker',
            style: TextStyle(color: Color(0xFF00E096), letterSpacing: 1)),
        content: const Text(
          'To enroll workers with face data, run the Python enrollment script on your laptop:\n\npython enroll_worker.py\n\nThe enrolled face data syncs to the app automatically.',
          style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void _showLogsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A1520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF)),
        ),
        title: const Text('Access Logs',
            style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 1)),
        content: const Text(
          'All access logs are stored offline in SQLite on the device.\n\nLogs include:\n• Worker ID and name\n• Timestamp\n• BPM reading\n• Liveness mode used\n• Access result\n\nLogs sync to NHAI Datalake 3.0 when internet is available.',
          style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
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
