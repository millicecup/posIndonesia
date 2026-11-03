// test/widget_test.dart
// Smoke test widget reusable. (File ini juga mencegah `flutter create .`
// membuat widget_test.dart default yang mereferensikan MyApp.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/shared/widgets/category_chip.dart';
import 'package:jejakpos/shared/widgets/poi_card.dart';
import 'package:jejakpos/shared/widgets/progress_badge.dart';

import 'helpers/test_data.dart';

void main() {
  testWidgets('PoiCard menampilkan id, nama, dan kategori', (tester) async {
    final poi = loadDataset().first;
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PoiCard(poi: poi, onTap: () => tapped = true)),
    ));
    expect(find.textContaining(poi.name), findsOneWidget);
    expect(find.text(poi.category.label), findsOneWidget);
    await tester.tap(find.byType(PoiCard));
    expect(tapped, isTrue);
  });

  testWidgets('ProgressBadge menampilkan 3/13 POI', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ProgressBadge(visited: 3, total: 13)),
    ));
    expect(find.text('3/13 POI'), findsOneWidget);
  });

  testWidgets('CategoryChip bisa dipilih', (tester) async {
    bool? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryChip(label: 'Koleksi Museum', onSelected: (v) => selected = v),
      ),
    ));
    await tester.tap(find.text('Koleksi Museum'));
    expect(selected, isTrue);
  });
}
