// lib/app/router.dart
// go_router: UI01-UI12 (Sprint 1, PB04) + tab Album (UI14) & Progres (UI21) (PIC: Farella).
// Ditambah: UI09 kontekstual, UI15-UI16 Photo Studio, UI17 Kuis, UI19 Pembuatan Perangko,
// UI22 Ringkasan Kunjungan + Postmark.
// Penomoran UI mengikuti PRD Bagian 5.1.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/album/presentation/album_screen.dart';
import '../features/audio_player/presentation/audio_player_screen.dart';
import '../features/home_explorer/presentation/home_explorer_screen.dart';
import '../features/map_navigation/presentation/map_screen.dart';
import '../features/map_navigation/presentation/route_guidance_screen.dart';
import '../features/map_navigation/presentation/trigger_alert_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/state/onboarding_state.dart';
import '../features/permission/presentation/permission_screen.dart';
import '../features/photo_studio/presentation/photo_studio_screen.dart';
import '../features/poi_detail/presentation/poi_detail_screen.dart';
import '../features/poi_list_search/presentation/poi_list_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/qr_scanner/presentation/qr_scanner_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/mystery_clue/presentation/mystery_clue_screen.dart';
import '../features/simulation_debug/presentation/simulation_panel_screen.dart';
import '../features/stamp_making/presentation/stamp_making_screen.dart';
import '../features/visit_summary/presentation/visit_summary_screen.dart';
import '../features/vision_tour/presentation/vision_tour_screen.dart';
import '../features/visual_tour_guide/presentation/visual_tour_guide_screen.dart';
import 'main_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Dibaca sekali saat start, agar router tidak dibuat ulang.
  final onboardingSeen = ref.read(onboardingSeenProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboardingSeen ? AppRoutes.explore : AppRoutes.onboarding,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.permission,
        builder: (context, state) => const PermissionScreen(),
      ),

      // ---------- 4 tab utama ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.explore,
              builder: (context, state) => const HomeExplorerScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (context, state) => const MapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.album,
              builder: (context, state) => const AlbumScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
        ],
      ),

      // ---------- Layar penuh di atas tab ----------
      GoRoute(
        path: AppRoutes.poiList,
        builder: (context, state) => PoiListScreen(
          initialCategoryId: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(
        path: '/navigate/:poiId',
        builder: (context, state) =>
            RouteGuidanceScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: '/trigger/:poiId',
        builder: (context, state) =>
            TriggerAlertScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: AppRoutes.tour,
        builder: (context, state) =>
            VisualTourGuideScreen(poiId: state.uri.queryParameters['poi']),
      ),
      GoRoute(
        path: '/photo-studio',
        builder: (context, state) =>
            PhotoStudioScreen(poiId: state.uri.queryParameters['poi']),
      ),
      GoRoute(
        path: '/quiz/:poiId',
        builder: (context, state) => QuizScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: '/mystery/:poiId',
        builder: (context, state) =>
            MysteryClueScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: '/stamp-making/:poiId',
        builder: (context, state) =>
            StampMakingScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: AppRoutes.summary,
        builder: (context, state) => const VisitSummaryScreen(),
      ),
      GoRoute(
        path: '/poi/:poiId',
        builder: (context, state) =>
            PoiDetailScreen(poiId: state.pathParameters['poiId']!),
        routes: [
          GoRoute(
            path: 'audio',
            builder: (context, state) =>
                AudioPlayerScreen(poiId: state.pathParameters['poiId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.visionTour,
        builder: (context, state) => const VisionTourScreen(),
      ),
      GoRoute(
        path: AppRoutes.simulation,
        builder: (context, state) => const SimulationPanelScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(child: Text('Rute ${state.uri} tidak ada')),
    ),
  );
});
