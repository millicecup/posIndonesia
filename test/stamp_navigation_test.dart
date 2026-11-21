import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/shared/widgets/stamp_unlocked_dialog.dart';
import 'helpers/test_data.dart';

void main() {
  for (final entry in {'Scan koleksi lain': '/qr', 'Lihat album': '/album', 'Kembali ke jelajah': '/explore'}.entries) {
    testWidgets('Stamp dialog: ${entry.key} opens ${entry.value}', (tester) async {
      final poi = loadDataset().first;
      final router = GoRouter(initialLocation: '/start', routes: [
        GoRoute(path: '/start', builder: (context, state) => Scaffold(body: TextButton(onPressed: () => showStampUnlockedDialog(context, poi: poi, isNew: true), child: const Text('Collect')))),
        for (final path in ['/qr', '/album', '/explore']) GoRoute(path: path, builder: (context, state) => Scaffold(body: Text('Destination $path'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collect'));
      await tester.pumpAndSettle();
      expect(find.text('Lanjut menjelajah'), findsNothing);
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('Destination ${entry.value}'), findsOneWidget);
    });
  }
}
