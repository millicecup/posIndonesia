import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/app/main_shell.dart';
import 'package:jejakpos/features/home_explorer/presentation/home_explorer_screen.dart';
import 'package:jejakpos/features/home_explorer/state/home_state.dart';
import 'package:jejakpos/features/home_explorer/widgets/explore_tutorial.dart';
import 'package:jejakpos/features/media_download/state/media_download_controller.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/media_service.dart';
import 'helpers/test_data.dart';

class NoDownload extends MediaDownloadController {
  @override
  Future<MediaDownloadState> build() async =>
      const MediaDownloadState(missing: 0);
}

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets('Redesigned Explore fits $width and opens guided tour',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pois = loadDataset();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(initialLocation: '/explore', routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MainShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/explore',
                  builder: (_, __) => const HomeExplorerScreen())
            ]),
            for (final path in ['/map', '/album', '/progress'])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: path, builder: (_, __) => Scaffold(body: Text(path)))
              ]),
          ],
        ),
        GoRoute(
            path: '/tour',
            builder: (_, __) => const Scaffold(body: Text('Tour destination'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            homeSummaryProvider.overrideWith((ref) async =>
                HomeSummary(pois: pois, progress: const VisitProgress.empty())),
            recommendedNextPoiProvider.overrideWith((ref) async => pois.first),
            mediaDownloadProvider.overrideWith(NoDownload.new),
            mediaSourceProvider
                .overrideWith((ref, args) async => BundledMedia(args.path)),
          ],
          child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.2)),
                  child: child!))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Panduan 1/10'), findsOneWidget);
      final tourBottom =
          tester.getBottomLeft(find.text('Mulai tur terpandu')).dy;
      final tipTop = tester.getTopLeft(find.text('Panduan 1/10')).dy;
      expect(tipTop, greaterThan(tourBottom));
      expect(tipTop - tourBottom, lessThan(100));
      const titles = [
        'Mulai dari tur terpandu',
        'Cari koleksi yang kamu inginkan',
        'Lihat lokasi koleksi',
        'Kenali pameran lewat kamera',
        'Pindai QR di dekat koleksi',
        'Kembali ke Jelajah',
        'Denah selalu mudah dijangkau',
        'Prangkomu tersimpan di Album',
        'Pantau perjalananmu',
        'Butuh panduan lagi?'
      ];
      for (var step = 1; step <= 10; step++) {
        expect(find.text('Panduan $step/10'), findsOneWidget);
        expect(find.text(titles[step - 1]), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/explore');
        if (step == 8) {
          final album =
              tester.getRect(find.byType(NavigationDestination).at(2));
          final tooltip =
              tester.getRect(find.text('Prangkomu tersimpan di Album'));
          expect(tooltip.bottom, lessThan(album.top));
        }
        final next = find.text(step == 10 ? 'Mulai menjelajah' : 'Lanjut');
        if (step == 10) {
          expect(tester.widget<Text>(next).maxLines, 1);
          expect(
              tester
                  .getSize(
                      find.widgetWithText(FilledButton, 'Mulai menjelajah'))
                  .width,
              greaterThan(230));
        }
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(prefs.getBool(exploreTutorialSeenKey), isTrue);
      router.go('/tour');
      await tester.pumpAndSettle();
      router.go('/explore');
      await tester.pumpAndSettle();
      expect(find.text('Panduan 1/10'), findsNothing);
      await tester.tap(find.byTooltip('Tutorial penggunaan'));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 1/10'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(
          find.text('Selamat datang di Museum Pos Indonesia'), findsOneWidget);
      await tester.ensureVisible(find.text('Mulai tur terpandu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai tur terpandu'));
      await tester.pumpAndSettle();
      expect(find.text('Tour destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
