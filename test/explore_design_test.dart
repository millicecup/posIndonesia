import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejakpos/app/theme.dart';
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
        GoRoute(
            path: '/explore', builder: (_, __) => const HomeExplorerScreen()),
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
      expect(find.text('Panduan 1/5'), findsOneWidget);
      final tourBottom = tester.getBottomLeft(find.text('Mulai tur terpandu')).dy;
      final tipTop = tester.getTopLeft(find.text('Panduan 1/5')).dy;
      expect(tipTop, greaterThan(tourBottom));
      expect(tipTop - tourBottom, lessThan(100));
      for (var step = 1; step <= 5; step++) {
        expect(find.text('Panduan $step/5'), findsOneWidget);
        final next = find.text(step == 5 ? 'Mengerti' : 'Lanjut');
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
      expect(find.text('Panduan 1/5'), findsNothing);
      await tester.tap(find.byTooltip('Tutorial penggunaan'));
      await tester.pumpAndSettle();
      expect(find.text('Panduan 1/5'), findsOneWidget);
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
