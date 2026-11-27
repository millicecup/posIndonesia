// lib/app/app.dart
// Root widget: tema, router, dan listener trigger POI global.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/map_navigation/presentation/museum_welcome_dialog.dart';
import '../providers/providers.dart';
import '../features/voice_guide/state/voice_guide_controller.dart';
import '../services/trigger_engine.dart';
import 'router.dart';
import 'routes.dart';
import 'theme.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class JejakPosApp extends ConsumerStatefulWidget {
  const JejakPosApp({super.key});

  @override
  ConsumerState<JejakPosApp> createState() => _JejakPosAppState();
}

class _JejakPosAppState extends ConsumerState<JejakPosApp> {
  /// Sambutan museum menunggu pengguna keluar dari splash/onboarding.
  bool _welcomePending = false;
  bool _welcomeOpen = false;
  GoRouter? _listenedRouter;

  static bool _inIntro(String location) =>
      location.startsWith(AppRoutes.splash) ||
      location.startsWith(AppRoutes.onboarding);

  void _onRouteChanged() {
    if (_welcomePending) _showMuseumWelcome();
  }

  /// DF-01: trigger saat pengguna memasuki area museum.
  Future<void> _showMuseumWelcome() async {
    final router = ref.read(routerProvider);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final ctx = rootNavigatorKey.currentContext;
    if (_welcomeOpen || ctx == null || _inIntro(location)) {
      _welcomePending = true;
      return;
    }
    _welcomePending = false;
    _welcomeOpen = true;
    final action = await showMuseumWelcomeDialog(ctx);
    _welcomeOpen = false;
    switch (action) {
      case MuseumWelcomeAction.tour:
        router.push(AppRoutes.tour);
      case MuseumWelcomeAction.recognize:
        router.push(AppRoutes.visionTour);
      case MuseumWelcomeAction.qr:
        router.push(AppRoutes.qrScanner);
      case MuseumWelcomeAction.later:
      case null:
        break;
    }
  }

  @override
  void dispose() {
    _listenedRouter?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    if (!identical(_listenedRouter, router)) {
      _listenedRouter?.routerDelegate.removeListener(_onRouteChanged);
      router.routerDelegate.addListener(_onRouteChanged);
      _listenedRouter = router;
    }

    ref.listen<AsyncValue<MuseumEvent>>(museumEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null ||
          event.type != MuseumEventType.entered ||
          !event.firstThisSession) {
        return;
      }
      _showMuseumWelcome();
    });

    // Aktifkan penghubung lokasi/beacon -> TriggerEngine sepanjang aplikasi.
    ref.watch(triggerCoordinatorProvider);
    // Pemandu suara otomatis (narasi saat mendekati / tiba di POI).
    ref.watch(voiceGuideProvider);

    // F02: info POI muncul OTOMATIS saat POI terpicu (hanya sekali per sesi,
    // diatur TriggerEngine): UI08 dibuka langsung, plus banner bergaya notifikasi.
    ref.listen<AsyncValue<TriggerEvent>>(triggerEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null ||
          event.source == TriggerSource.qr ||
          event.type != TriggerEventType.triggered) {
        return;
      }
      final target = AppRoutes.triggerAlert(event.poi.id);
      final current = router.routerDelegate.currentConfiguration.uri.toString();
      final onboarding = current.startsWith(AppRoutes.splash) ||
          current.startsWith(AppRoutes.onboarding) ||
          current.startsWith(AppRoutes.permission);
      if (current != target && !onboarding) router.push(target);
      rootScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text('Kamu berada di zona ${event.poi.id}: ${event.poi.name}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'LIHAT',
              onPressed: () =>
                  router.push(AppRoutes.triggerAlert(event.poi.id)),
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
