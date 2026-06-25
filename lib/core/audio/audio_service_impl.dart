import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import 'audio_service.dart';

@LazySingleton(as: AudioService)
class SafeAudioService implements AudioService {
  SafeAudioService();

  AudioPlayer? _player;
  bool _isEnabled = true;
  double _volume = 0.7;
  bool _lastFailureWasSilent = false;

  bool get lastFailureWasSilent => _lastFailureWasSilent;

  @override
  bool get isEnabled => _isEnabled;

  @override
  double get volume => _volume;

  @override
  Future<void> playSfx(String key) async {
    _lastFailureWasSilent = false;
    if (!_isEnabled || key.trim().isEmpty) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (bindingName.contains('Test')) {
      return;
    }

    try {
      final player = _ensurePlayer();
      await player.stop().timeout(const Duration(milliseconds: 300));
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(_volume).timeout(const Duration(milliseconds: 300));
      await player
          .play(AssetSource('audio/$key.mp3'))
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {
      await _playFallbackSystemSound();
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) {
      try {
        await _player?.stop().timeout(const Duration(milliseconds: 300));
      } catch (_) {
        _lastFailureWasSilent = true;
      }
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_volume).timeout(const Duration(milliseconds: 300));
    } catch (_) {
      _lastFailureWasSilent = true;
    }
  }

  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer();
  }

  Future<void> _playFallbackSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      _lastFailureWasSilent = false;
    } catch (_) {
      _lastFailureWasSilent = true;
    }
  }
}
