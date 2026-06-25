import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/audio/audio_service_impl.dart';

void main() {
  test('toggles sound for the current app session', () async {
    final service = SafeAudioService();

    expect(service.isEnabled, isTrue);

    await service.setEnabled(false);
    expect(service.isEnabled, isFalse);

    await service.setEnabled(true);
    expect(service.isEnabled, isTrue);
  });
}
