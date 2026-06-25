abstract class AudioService {
  Future<void> playSfx(String key);
  Future<void> setEnabled(bool enabled);
  Future<void> setVolume(double volume);
  bool get isEnabled;
  double get volume;
}
