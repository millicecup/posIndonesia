// lib/app/app.dart
// Root widget: tema, router, dan listener trigger POI global.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/providers.dart';
import '../features/voice_guide/state/voice_guide_controller.dart';
import '../services/trigger_engine.dart';
import 'router.dart';
import 'routes.dart';
import 'theme.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class JejakPosApp extends ConsumerWidget {
  const JejakPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Aktifkan penghubung lokasi/beacon -> TriggerEngine sepanjang aplikasi.
    ref.watch(triggerCoordinatorProvider);
    // Pemandu suara otomatis (narasi saat mendekati / tiba di POI).
    ref.watch(voiceGuideProvider);

    // F02: info POI muncul OTOMATIS saat POI terpicu (hanya sekali per sesi,
    // diatur TriggerEngine): UI08 dibuka langsung, plus banner bergaya notifikasi.
    ref.listen<AsyncValue<TriggerEvent>>(triggerEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null || event.type != TriggerEventType.triggered) return;
      final target = AppRoutes.triggerAlert(event.poi.id);
      final current = router.routerDelegate.currentConfiguration.uri.toString();
      final onboarding = current.startsWith(AppRoutes.onboarding) ||
          current.startsWith(AppRoutes.permission);
      if (current != target && !onboarding) router.push(target);
      rootScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Kamu berada di zona ${event.poi.id}: ${event.poi.name}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'LIHAT',
              onPressed: () => router.push(AppRoutes.triggerAlert(event.poi.id)),
            ),
          ),
        );
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
    );
  }
}
