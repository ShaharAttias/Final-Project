import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'yolo_service.dart';
import 'camera_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VisionApp(),
  ));
}

class VisionApp extends StatefulWidget {
  const VisionApp({super.key});

  @override
  State<VisionApp> createState() => _VisionAppState();
}

class _VisionAppState extends State<VisionApp> {
  final CameraService _cameraService = CameraService();
  final YoloService _yoloService = YoloService();
  final FlutterTts tts = FlutterTts();

  bool isDetecting = false;
  bool isRunning = false;
  List<Map<String, dynamic>> yoloResults = [];

  @override
  void initState() {
    super.initState();
    _initializeSystem();
    _setupTts();
  }

  // הגדרת הגדרות שפה בסיסיות לדיבור
  void _setupTts() async {
    await tts.setLanguage("he-IL"); // עברית
    await tts.setSpeechRate(0.6);   // קצב דיבור נוח
  }

  Future<void> _initializeSystem() async {
    try {
      await Future.wait([
        _cameraService.initialize(),
        _yoloService.initModel(),
      ]);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("System Initialization Error: $e");
    }
  }

  void startDetection() async {
    if (!_cameraService.isInitialized || !_yoloService.isLoaded) return;

    // משוב למשתמש: רטט ודיבור
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    await tts.speak("זיהוי הופעל");

    setState(() => isRunning = true);

    _cameraService.startStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;

      try {
        final result = await _yoloService.detectObjects(
          image.planes.map((plane) => plane.bytes).toList(),
          image.height,
          image.width,
        );

        if (mounted) {
          setState(() {
            yoloResults = result;
          });
        }
      } catch (e) {
        print("Detection loop error: $e");
      } finally {
        isDetecting = false;
      }
    });
  }

  void stopDetection() async {
    await _cameraService.stopStream();

    // משוב למשתמש: רטט ודיבור
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 50, 50]); // רטט כפול לכיבוי
    }
    await tts.speak("זיהוי הופסק");

    setState(() {
      isRunning = false;
      yoloResults = [];
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _yoloService.dispose();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraService.isInitialized || !_yoloService.isLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blueGrey),
              SizedBox(height: 20),
              Text("מכין מצלמה ומודל...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vision Assistant"),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: _cameraService.controller!.value.aspectRatio,
            child: CameraPreview(_cameraService.controller!),
          ),

          CustomPaint(
            painter: YoloPainter(yoloResults),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: isRunning ? Colors.redAccent : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: isRunning ? stopDetection : startDetection,
                icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, color: Colors.white),
                label: Text(
                  isRunning ? "עצור זיהוי" : "הפעל זיהוי",
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YoloPainter extends CustomPainter {
  final List<Map<String, dynamic>> results;
  YoloPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent;

    for (var result in results) {
      final box = result['box'];

      double left = box[0] * size.width / 640;
      double top = box[1] * size.height / 640;
      double right = box[2] * size.width / 640;
      double bottom = box[3] * size.height / 640;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      final text = "${result['tag']} ${(box[4] * 100).toStringAsFixed(0)}%";
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      final bgPaint = Paint()..color = Colors.redAccent.withOpacity(0.7);
      canvas.drawRect(
        Rect.fromLTWH(left, top > 25 ? top - 25 : top, textPainter.width + 8, 20),
        bgPaint,
      );

      textPainter.paint(canvas, Offset(left + 4, top > 25 ? top - 23 : top + 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}