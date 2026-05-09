import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';


class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> playAlarm() async {
    // Note: User needs to provide assets/alarm.mp3
    // For now, using a fallback or system sound if possible, 
    // but standard is assets.
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  Future<void> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/emergency_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _recorder.start(config, path: filePath);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
  }
}

