import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/audio/audio_service_impl.dart';

void main() {
  test('missing sound requests stay non-blocking', () async {
    final service = SafeAudioService();

    for (var i = 0; i < 10; i += 1) {
      await service.playSfx('missing_$i');
    }

    expect(service.isEnabled, isTrue);
    expect(service.volume, closeTo(0.7, 0.001));

    await service.setEnabled(false);
    await service.playSfx('missing_disabled');

    expect(service.isEnabled, isFalse);
  });
}
