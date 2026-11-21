import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/map_navigation/presentation/map_screen.dart';
import 'package:jejakpos/features/map_navigation/presentation/museum_map_view.dart';
import 'package:jejakpos/features/map_navigation/state/map_state.dart';
import 'package:jejakpos/features/permission/state/permission_controller.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/permission_service.dart';
import 'package:jejakpos/services/location_service.dart';
import 'helpers/test_data.dart';

class EmptyProgress extends ProgressController {
  @override
  Future<VisitProgress> build() async => const VisitProgress.empty();
}

class TestPermissions extends PermissionService {
  final requested = <AppPermissionType>[];
  @override
  Future<AppPermissionStatus> check(AppPermissionType type) async =>
      AppPermissionStatus.granted;
  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async {
    requested.add(type);
    return AppPermissionStatus.granted;
  }
}

class TestLocation extends LocationService {
  int requested = 0;
  @override
  Future<LocationStatus> checkStatus() async => LocationStatus.granted;
  @override
  Future<LocationStatus> requestPermission() async {
    requested++;
    return LocationStatus.granted;
  }
}

void main() {
  test('Request all needs location and camera, never Bluetooth', () async {
    final permissions = TestPermissions();
    final location = TestLocation();
    final container = ProviderContainer(overrides: [
      permissionServiceProvider.overrideWithValue(permissions),
      locationServiceProvider.overrideWithValue(location)
    ]);
    addTearDown(container.dispose);
    await container.read(permissionControllerProvider.future);
    await container.read(permissionControllerProvider.notifier).requestAll();
    expect(location.requested, 1);
    expect(permissions.requested,
        [AppPermissionType.camera, AppPermissionType.notification]);
    expect(
        (await container.read(permissionControllerProvider.future)).permissions,
        isNot(contains(AppPermissionType.bluetooth)));
  });
  testWidgets('Selected POI card sits below map without covering it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(overrides: [
      poisProvider.overrideWith((ref) async => loadDataset().take(11).toList()),
      progressProvider.overrideWith(EmptyProgress.new),
      poiProximityProvider.overrideWith((ref) => const Stream.empty()),
      selectedMapPoiIdProvider.overrideWith((ref) => 'P11'),
    ], child: MaterialApp(theme: AppTheme.light, home: const MapScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final map = tester.getRect(find.byType(MuseumMapView));
    final panel = tester.getRect(find.byType(Card));
    expect(panel.top, greaterThanOrEqualTo(map.bottom));
    expect(find.text('Detail'), findsOneWidget);
  });
}
