// lib/features/voice_guide/presentation/listen_to_poi.dart
// Satu pintu untuk tombol "Dengarkan" di UI08/UI09/UI10:
// - POI dengan rekaman asli (mis. Mars Pos Indonesia P10) -> pemutar audio (UI11).
// - POI lain -> cerita POI dibacakan pemandu suara (TTS bahasa Indonesia).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../state/voice_guide_controller.dart';

Future<void> listenToPoi(BuildContext context, WidgetRef ref, Poi poi,
    {bool replace = false}) async {
  final guide = ref.read(voiceGuideProvider.notifier);
  if (poi.hasRealAudio) {
    await guide.stop();
    if (!context.mounted) return;
    replace
        ? context.pushReplacement(AppRoutes.audioPlayer(poi.id))
        : context.push(AppRoutes.audioPlayer(poi.id));
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Pemandu suara membacakan cerita ${poi.name}'),
      duration: const Duration(seconds: 3),
    ));
  await guide.narratePoi(poi);
}
