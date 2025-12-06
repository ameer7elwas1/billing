import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qcbcjyhqgxwuqutzkxrh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjYmNqeWhxZ3h3dXF1dHpreHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMDE3NjQsImV4cCI6MjA2Njc3Nzc2NH0.y-hQVa6nzBpCMpXL7XbcWPMGafATvnMez3lAmFvb2zY',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginPage(), debugShowCheckedModeBanner: false);
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  final supabase = Supabase.instance.client;

  void login() async {
    setState(() => loading = true);
    final response = await supabase.rpc(
      'authenticate_employee',
      params: {
        'employee_phone': phoneController.text,
        'employee_password': passwordController.text,
      },
    );
    print('Supabase response: ${response.data}');
    print('Supabase error: ${response.error}');
    if (response.error != null ||
        response.data == null ||
        response.data['success'] == false) {
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(content: Text('خطأ في رقم الهاتف أو كلمة المرور')),
      );
      setState(() => loading = false);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingPage(employee: response.data['employee']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(hintText: 'رقم الهاتف'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(hintText: 'كلمة المرور'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingPage extends StatefulWidget {
  final dynamic employee;
  TrackingPage({required this.employee});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  MapboxMapController? mapController;
  final supabase = Supabase.instance.client;
  static const String mapboxToken =
      'pk.eyJ1IjoiYW1lZXI3ZWx3YXMiLCJhIjoiY21iODAxaTFyMGFsajJqc2J2dGtvY2pmdSJ9.MNY-7y2onlfAnM0PUhNt8g';
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    // تحميل صورة marker-15 عند إنشاء الخريطة
    startTracking();
  }

  Future<void> _addMarkerImage() async {
    final ByteData bytes = await rootBundle.load('assets/marker-15.png');
    final Uint8List list = bytes.buffer.asUint8List();
    if (mapController != null) {
      try {
        await mapController!.addImage('marker-15', list);
      } catch (e) {
        // إذا كانت الصورة مضافة مسبقاً، تجاهل الخطأ
      }
    }
  }

  void _onMapCreated(MapboxMapController controller) async {
    mapController = controller;
    await _addMarkerImage();
  }

  void startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      await supabase.from('logs').insert({
        'employee_id': widget.employee['id'],
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'occurred_at': DateTime.now().toIso8601String(),
        'notes': 'تتبع تلقائي Flutter',
      });
      if (mapController != null) {
        await _addMarkerImage();
        mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(position.latitude, position.longitude),
            iconImage: 'marker-15',
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الموظف ${widget.employee['name']}')),
      body: MapboxMap(
        accessToken: mapboxToken,
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(33.3152, 44.3661),
          zoom: 14,
        ),
      ),
    );
  }
}
