import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/features/splash/presentation/splash_screen.dart';
import 'package:jejakpos/features/onboarding/presentation/onboarding_screen.dart';
import 'package:jejakpos/features/album/presentation/album_screen.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/shared/widgets/stamp_unlocked_dialog.dart';
import 'helpers/test_data.dart';

void main() {
  testWidgets('Splash continues to introduction, never straight to Home',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
            builder: (context) => SplashScreen(
                playSound: false,
                onFinished: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) =>
                            const Scaffold(body: Text('Introduction'))))))));
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.bySemanticsLabel('Ikon prangko JejakPOS'), findsOneWidget);
    expect(find.text('Lewati animasi'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();
    expect(find.text('Introduction'), findsOneWidget);
  });
  testWidgets(
      'Introduction supports vertical scrolling and horizontal swipes on a short phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.2)),
                child: child!))));
    await tester.pumpAndSettle();
    final scroller = find.byType(SingleChildScrollView).first;
    final position = tester
        .state<ScrollableState>(find
            .descendant(of: scroller, matching: find.byType(Scrollable))
            .first)
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(scroller, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    await tester.drag(find.byType(PageView), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, 0.01));
    expect(find.text('Explore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('Compact album and onboarding fit $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pois = loadDataset().take(11).toList();
      await tester.pumpWidget(ProviderScope(
          key: UniqueKey(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            poisProvider.overrideWith((ref) async => pois),
            poiRepositoryProvider.overrideWithValue(buildRepository()),
          ],
          child:
              MaterialApp(theme: AppTheme.light, home: const AlbumScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final frames = tester.widgetList<StampFrame>(find.byType(StampFrame));
      expect(frames.first.size, greaterThan(92));
      final topFirst = tester.getTopLeft(find.text('P01')).dy;
      final topNextRow = tester.getTopLeft(find.text('P03')).dy;
      expect(topNextRow - topFirst, lessThan(280));
      await tester.pumpWidget(ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
              theme: AppTheme.light, home: const OnboardingScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Museum Pos Indonesia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Explore'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Collect'), findsOneWidget);
      expect(find.text('Lewati pengantar'), findsNothing);
      expect(find.text('Mulai menjelajah'), findsOneWidget);
    });
  }
}
