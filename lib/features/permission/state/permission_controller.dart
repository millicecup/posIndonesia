// lib/features/permission/state/permission_controller.dart
// State UI02: status izin + status lokasi (PIC: Firda, backend: Matilda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/location_status.dart';
import '../../../providers/providers.dart';
import '../../../services/permission_service.dart';

class PermissionOverview {
  const PermissionOverview({
    required this.permissions,
    required this.locationStatus,
  });

  final Map<AppPermissionType, AppPermissionStatus> permissions;
  final LocationStatus locationStatus;
}

class PermissionController extends AsyncNotifier<PermissionOverview> {
  @override
  Future<PermissionOverview> build() => _load();

  Future<PermissionOverview> _load() async {
    final permissions = await ref.read(permissionServiceProvider).checkAll();
    final location = await ref.read(locationServiceProvider).checkStatus();
    return PermissionOverview(
        permissions: permissions, locationStatus: location);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
    // Beritahu provider lokasi agar stream GPS dibuat ulang.
    ref.invalidate(locationStatusProvider);
  }

  Future<void> request(AppPermissionType type) async {
    if (type == AppPermissionType.location) {
      await ref.read(locationServiceProvider).requestPermission();
    } else {
      await ref.read(permissionServiceProvider).request(type);
    }
    await refresh();
  }

  Future<void> requestAll() async {
    for (final type in PermissionService.requiredPermissions) {
      if (type == AppPermissionType.location) {
        await ref.read(locationServiceProvider).requestPermission();
      } else {
        await ref.read(permissionServiceProvider).request(type);
      }
    }
    await refresh();
  }

  Future<void> openSettings() =>
      ref.read(permissionServiceProvider).openSettings();

  Future<void> openLocationSettings() =>
      ref.read(locationServiceProvider).openLocationSettings();
}

final permissionControllerProvider =
    AsyncNotifierProvider<PermissionController, PermissionOverview>(
        PermissionController.new);
