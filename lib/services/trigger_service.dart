import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

class TriggerService extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  ShakeDetector? _shakeDetector;
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isShakeActive = false;
  String _status = "Initializing...";
  VoidCallback? onTrigger;

  bool get isListening => _isListening;
  bool get isShakeActive => _isShakeActive;
  String get status => _status;

  Future<void> init() async {
    await initShake();
    await initSpeech();
    _status = "Protected";
    notifyListeners();
  }

  Future<void> initShake() async {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        debugPrint("Shake detected!");
        onTrigger?.call();
      },
      shakeThresholdGravity: 2.7, // High sensitivity
    );
    _isShakeActive = true;
  }

  Future<void> initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_isListening) _startListening(); // Restart if it stops
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      _startListening();
    }
  }

  void _startListening() async {
    final keyword = await _prefs.getKeyword();
    _isListening = true;
    notifyListeners();

    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.toLowerCase().contains(keyword.toLowerCase())) {
          debugPrint("Keyword detected!");
          onTrigger?.call();
        }
      },
      listenFor: const Duration(hours: 1), // Long duration for background-like feel
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void stopAll() {
    _shakeDetector?.stopListening();
    _speech.stop();
    _isListening = false;
    _isShakeActive = false;
    _status = "Inactive";
    notifyListeners();
  }

  void resumeAll() {
    initShake();
    _startListening();
    _status = "Protected";
    notifyListeners();
  }
}
