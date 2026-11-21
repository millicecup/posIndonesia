import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_activity_launcher.dart';
import 'helpers/test_data.dart';

void main() {
  testWidgets('P03 timeline works without unique facts and expands years', (tester) async {
    final poi = loadDataset().firstWhere((p) => p.id == 'P03');
    expect(poi.keyFacts, isEmpty);
    expect(poiTimelineEntries(poi), hasLength(6));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => openPoiActivity(context, poi, PoiActivity.timeline), child: const Text('Timeline'))))));
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Masa Hindia Belanda'), findsOneWidget);
    await tester.tap(find.text('1945'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jawatan Pos, Telegraf dan Telepon'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup linimasa'));
    await tester.pumpAndSettle();
    expect(find.text('Masa Hindia Belanda'), findsNothing);
  });
}
