import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/features/qr_scanner/presentation/qr_scanner_screen.dart';

void main() {
  for (final direct in [true, false]) {
    testWidgets('QR back returns to Explore (direct: $direct)', (tester) async {
      final router = GoRouter(initialLocation: direct ? '/qr' : '/explore', routes: [
        GoRoute(path: '/explore', builder: (context, state) => Scaffold(body: TextButton(onPressed: () => context.push('/qr'), child: const Text('Open QR')))),
        GoRoute(path: '/qr', builder: (context, state) => const QrScannerScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      if (!direct) {
        await tester.tap(find.text('Open QR'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Pindai QR koleksi'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Open QR'), findsOneWidget);
    });
  }
}
