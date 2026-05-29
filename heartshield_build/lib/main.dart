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
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('?', style: TextStyle(color: Color(0xFFFF3D71), fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('HEARTSHIELD', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  Text('NHAI Innovation Hackathon 7.0', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00E096)), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.circle, size: 8, color: Color(0xFF00E096)),
                  SizedBox(width: 6),
                  Text('100% OFFLINE', style: TextStyle(color: Color(0xFF00E096), fontSize: 12, letterSpacing: 1.5)),
                ]),
              ),
              const SizedBox(height: 32),
              const Text('Offline facial recognition\nwith heartbeat liveness detection.', style: TextStyle(color: Color(0xFFE8F4F8), fontSize: 22, fontWeight: FontWeight.w300, height: 1.4)),
              const SizedBox(height: 12),
              const Text('Works in zero-network zones.\nBuilt for NHAI Datalake 3.0.', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 15, height: 1.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HeartShieldScreen(onResult: (result) { Navigator.pop(context); }))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFF0A1520), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.face_retouching_natural, color: Color(0xFF00E5FF), size: 24),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('START SCANNER', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text('Scan face with heartbeat detection', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 12)),
                    ])),
                    Icon(Icons.arrow_forward_ios, color: const Color(0xFF00E5FF).withOpacity(0.5), size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  backgroundColor: const Color(0xFF050A0F),
                  appBar: AppBar(title: const Text('ENROLL WORKER', style: TextStyle(color: Color(0xFF00E096))), backgroundColor: const Color(0xFF0A1520), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)), onPressed: () => Navigator.pop(context))),
                  body: const Padding(padding: EdgeInsets.all(24), child: Text('Run python enroll_worker.py on your laptop to enroll workers.\n\nEnrolled face data syncs to this app automatically.', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 15, height: 1.8))),
                ))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFF0A1520), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E096).withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined, color: Color(0xFF00E096), size: 24),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('ENROLL WORKER', style: TextStyle(color: Color(0xFF00E096), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text('Register a new NHAI worker', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 12)),
                    ])),
                    Icon(Icons.arrow_forward_ios, color: const Color(0xFF00E096).withOpacity(0.5), size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  backgroundColor: const Color(0xFF050A0F),
                  appBar: AppBar(title: const Text('ACCESS LOGS', style: TextStyle(color: Color(0xFF00E5FF))), backgroundColor: const Color(0xFF0A1520), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)), onPressed: () => Navigator.pop(context))),
                  body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('All access logs are stored offline in SQLite.\n\nLogs include worker ID, timestamp, BPM reading, liveness mode, and result.\n\nLogs sync to NHAI Datalake 3.0 when internet is available.', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 15, height: 1.8), textAlign: TextAlign.center))),
                ))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFF0A1520), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7AA8C0).withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.list_alt_outlined, color: Color(0xFF7AA8C0), size: 24),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('VIEW LOGS', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text('Access logs stored offline', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 12)),
                    ])),
                    Icon(Icons.arrow_forward_ios, color: const Color(0xFF7AA8C0).withOpacity(0.5), size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Center(child: Text('Submission Deadline: 05 June 2026', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
