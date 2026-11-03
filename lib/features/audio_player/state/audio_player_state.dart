// lib/features/audio_player/state/audio_player_state.dart
// Stream posisi/durasi/status audio untuk UI11 (PIC: Belinda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../services/audio_service.dart';

final audioPositionProvider = StreamProvider.autoDispose<Duration>(
  (ref) => ref.watch(audioServiceProvider).positionStream,
);

final audioDurationProvider = StreamProvider.autoDispose<Duration?>(
  (ref) => ref.watch(audioServiceProvider).durationStream,
);

final audioStatusProvider = StreamProvider.autoDispose<AudioPlaybackStatus>(
  (ref) => ref.watch(audioServiceProvider).statusStream,
);
