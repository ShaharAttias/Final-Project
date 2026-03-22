import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // פתיחת המצלמה האחורית
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // בחירת המצלמה האחורית (לרוב הראשונה ברשימה)
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  // התחלת הזרמת הפריימים
  void startStream(Function(CameraImage) onFrame) {
    if (_controller == null || !_isInitialized) return;
    _controller!.startImageStream(onFrame);
  }

  // עצירת הזרם
  Future<void> stopStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}