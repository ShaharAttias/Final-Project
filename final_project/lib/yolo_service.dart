import 'dart:typed_data';
import 'package:flutter_vision/flutter_vision.dart';

class YoloService {
  late FlutterVision vision;
  bool isLoaded = false;

  YoloService() {
    vision = FlutterVision();
  }

  // טעינת המודל
  Future<void> initModel() async {
    try {
      await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/yolov8n_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true, // שימוש במאיץ גרפי לביצועים מהירים
      );
      isLoaded = true;
      print("YoloService: Model loaded successfully");
    } catch (e) {
      print("YoloService: Error loading model: $e");
    }
  }

  // הרצה על פריימים מהמצלמה עם סינון נתונים
  Future<List<Map<String, dynamic>>> detectObjects(List<Uint8List> bytesList, int h, int w) async {
    if (!isLoaded) return [];

    try {
      final results = await vision.yoloOnFrame(
        bytesList: bytesList,
        imageHeight: h,
        imageWidth: w,
        iouThreshold: 0.4,
        confThreshold: 0.5,
        classThreshold: 0.2,
      );

      // הדפסת התוצאות ל-Console לצרכי ניטור (Debug)
      if (results.isNotEmpty) {
        for (var res in results) {
          String label = res['tag'];
          double confidence = res['box'][4];
          print("Detected: $label (${(confidence * 100).toStringAsFixed(0)}%)");
        }
      }

      return results;
    } catch (e) {
      print("YoloService: Detection error: $e");
      return [];
    }
  }

  // סגירת המודל לשחרור זיכרון
  void dispose() {
    if (isLoaded) {
      vision.closeYoloModel();
      print("YoloService: Model closed");
    }
  }
}