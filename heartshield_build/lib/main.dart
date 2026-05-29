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
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF050A0F)),
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
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00E5FF), width: 1.5), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('♥', style: TextStyle(color: Color(0xFFFF3D71), fontSize: 22)))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('HEARTSHIELD', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  Text('NHAI Innovation Hackathon 7.0', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00E096)), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.circle, size: 7, color: Color(0xFF00E096)),
                  SizedBox(width: 6),
                  Text('100% OFFLINE', style: TextStyle(color: Color(0xFF00E096), fontSize: 11, letterSpacing: 1.5)),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('Offline facial recognition\nwith heartbeat liveness detection.',
                style: TextStyle(color: Color(0xFFE8F4F8), fontSize: 20, fontWeight: FontWeight.w300, height: 1.4)),
              const SizedBox(height: 8),
              const Text('Zero-network zones. NHAI Datalake 3.0.',
                style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
              const Spacer(),
              _Btn(label: 'START SCANNER', sub: 'Scan face with heartbeat detection',
                icon: Icons.face_retouching_natural, color: const Color(0xFF00E5FF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HeartShieldScreen(onResult: (r) => Navigator.pop(context))))),
              const SizedBox(height: 10),
              _Btn(label: 'ENROLL WORKER', sub: 'Register a new NHAI worker',
                icon: Icons.person_add_outlined, color: const Color(0xFF00E096),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _EnrollPage()))),
              const SizedBox(height: 10),
              _Btn(label: 'VIEW LOGS', sub: 'All access logs stored offline',
                icon: Icons.list_alt_outlined, color: const Color(0xFF7AA8C0),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _LogsPage()))),
              const SizedBox(height: 20),
              Center(child: Text('Deadline: 05 June 2026', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label, sub; final IconData icon; final Color color; final VoidCallback onTap;
  const _Btn({required this.label, required this.sub, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF0A1520), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 22), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          Text(sub, style: const TextStyle(color: Color(0xFF7AA8C0), fontSize: 11)),
        ])),
        Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.4), size: 13),
      ])));
}

class _EnrollPage extends StatefulWidget {
  const _EnrollPage({Key? key}) : super(key: key);
  @override
  State<_EnrollPage> createState() => _EnrollPageState();
}

class _EnrollPageState extends State<_EnrollPage> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  String _role = 'Field Inspector';
  bool _done = false;
  final roles = ['Field Inspector','Toll Operator','Site Engineer','Security Guard','Supervisor'];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050A0F),
    appBar: AppBar(title: const Text('ENROLL WORKER', style: TextStyle(color: Color(0xFF00E096), letterSpacing: 2, fontSize: 15)),
      backgroundColor: const Color(0xFF0A1520),
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)), onPressed: () => Navigator.pop(context))),
    body: _done ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle, color: Color(0xFF00E096), size: 72),
        const SizedBox(height: 16),
        Text('${_name.text} enrolled!', style: const TextStyle(color: Color(0xFF00E096), fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Worker saved to device', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
      ])) :
    Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('WORKER ID', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      TextField(controller: _id, style: const TextStyle(color: Color(0xFFE8F4F8)),
        decoration: InputDecoration(hintText: 'e.g. NHAI_001', hintStyle: const TextStyle(color: Color(0xFF7AA8C0)),
          filled: true, fillColor: const Color(0xFF0A1520),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)))),
      const SizedBox(height: 16),
      const Text('FULL NAME', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      TextField(controller: _name, style: const TextStyle(color: Color(0xFFE8F4F8)),
        decoration: InputDecoration(hintText: 'e.g. Ramesh Kumar', hintStyle: const TextStyle(color: Color(0xFF7AA8C0)),
          filled: true, fillColor: const Color(0xFF0A1520),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 0.5)))),
      const SizedBox(height: 16),
      const Text('ROLE', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 11, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFF0A1520), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 0.5)),
        child: DropdownButton<String>(value: _role, isExpanded: true, dropdownColor: const Color(0xFF0A1520), underline: const SizedBox(),
          style: const TextStyle(color: Color(0xFFE8F4F8), fontSize: 14),
          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _role = v!))),
      const Spacer(),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_id.text.isEmpty || _name.text.isEmpty) return;
            setState(() => _done = true);
            Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E096), foregroundColor: const Color(0xFF050A0F),
            padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('ENROLL WORKER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)))),
    ])),
  );
}

class _LogsPage extends StatelessWidget {
  const _LogsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050A0F),
    appBar: AppBar(title: const Text('ACCESS LOGS', style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 2, fontSize: 15)),
      backgroundColor: const Color(0xFF0A1520),
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)), onPressed: () => Navigator.pop(context))),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Icon(Icons.check_circle_outline, color: Color(0xFF00E5FF), size: 64),
      SizedBox(height: 16),
      Text('All logs stored on device', style: TextStyle(color: Color(0xFFE8F4F8), fontSize: 16)),
      SizedBox(height: 8),
      Text('Worker ID  ·  Timestamp  ·  BPM  ·  Result', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13)),
      SizedBox(height: 24),
      Padding(padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text('Logs sync to NHAI Datalake 3.0\nautomatically when internet returns', style: TextStyle(color: Color(0xFF7AA8C0), fontSize: 13, height: 1.6), textAlign: TextAlign.center)),
    ])),
  );
}
