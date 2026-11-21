// lib/features/permission/presentation/permission_screen.dart
// UI02 Izin Akses - BERFUNGSI (bukti PB02). Wireframe: PRD Gambar 5.1 tengah.
// TODO(Firda): tampilan toggle per izin sesuai wireframe; pindahkan panel "Deteksi lokasi"
//   & log ke halaman debug jika sudah tidak dibutuhkan sebagai evidence.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/location_status.dart';
import '../../../providers/providers.dart';
import '../../../services/permission_service.dart';
import '../state/permission_controller.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  UserPosition? _singleReading;
  String? _readingError;
  bool _reading = false;

  Future<void> _readOnce() async {
    setState(() {
      _reading = true;
      _readingError = null;
    });
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      if (mounted) setState(() => _singleReading = pos);
    } catch (e) {
      if (mounted) setState(() => _readingError = e.toString());
      AppLogger.error(AppConstants.logTagLocation, 'Baca lokasi gagal', e);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(permissionControllerProvider);
    final controller = ref.read(permissionControllerProvider.notifier);
    final simulation = ref.watch(simulationModeProvider);
    final livePosition = ref.watch(positionStreamProvider);
    final logs =
        ref.watch(detectionLogProvider).valueOrNull ?? const <LogEntry>[];
    final locationLogs = logs
        .where((e) =>
            e.tag == AppConstants.logTagLocation ||
            e.tag == AppConstants.logTagTrigger ||
            e.tag == 'SIMULASI' ||
            e.tag == 'IZIN')
        .toList()
        .reversed
        .take(30)
        .toList();

    return Scaffold(
      appBar: JejakAppBar(
        title: const Text('Izin dan status lokasi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang status',
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'JejakPOS menggunakan lokasi untuk memicu informasi saat kamu mendekati koleksi. '
            'Kamera digunakan untuk mengenali pameran (CV), memindai QR, dan Photo Studio. '
            'Notifikasi digunakan untuk memberi tahu saat kamu mendekati koleksi.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
                'Jika lokasi tidak aktif, kamu tetap bisa mengenali koleksi melalui kamera atau memindai QR.'),
          ),
          const SizedBox(height: 12),
          overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Gagal membaca izin: $e'),
            data: (data) => Column(
              children: [
                _LocationStatusTile(
                  status: data.locationStatus,
                  onOpenSettings:
                      data.locationStatus == LocationStatus.serviceDisabled
                          ? controller.openLocationSettings
                          : controller.openSettings,
                ),
                for (final type in PermissionService.requiredPermissions)
                  _PermissionTile(
                    type: type,
                    status:
                        data.permissions[type] ?? AppPermissionStatus.denied,
                    onRequest: () => controller.request(type),
                    onOpenSettings: controller.openSettings,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: controller.requestAll,
            icon: const Icon(Icons.verified_user),
            label: const Text('Izinkan semua'),
          ),
          const Divider(height: 32),

          // ---------- Deteksi lokasi ----------
          Text('Deteksi lokasi',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            simulation
                ? 'Sumber: SIMULASI (SimulationService)'
                : 'Sumber: GPS perangkat/emulator',
            style: TextStyle(
                color: simulation ? AppColors.warning : AppColors.success),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _reading ? null : _readOnce,
            icon: const Icon(Icons.my_location),
            label: Text(_reading ? 'Membaca...' : 'Baca lokasi sekali (GPS)'),
          ),
          if (_singleReading != null) Text('Hasil: $_singleReading'),
          if (_readingError != null)
            Text(_readingError!,
                style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gps_fixed, color: AppColors.orange),
              title: const Text('Posisi terkini (stream)'),
              subtitle: Text(livePosition.when(
                data: (p) => p.toString(),
                loading: () => simulation
                    ? 'Menunggu posisi simulasi... (buka panel simulasi)'
                    : 'Menunggu GPS... (pastikan izin diberikan)',
                error: (e, _) => 'Error: $e',
              )),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.simulation),
            icon: const Icon(Icons.bug_report),
            label: const Text('Buka panel simulasi emulator'),
          ),
          const Divider(height: 32),

          // ---------- Log deteksi (bukti PB02) ----------
          Text('Log deteksi (terbaru di atas)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Container(
            height: 220,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: locationLogs.isEmpty
                ? const Text('Belum ada log.',
                    style: TextStyle(color: Colors.white70))
                : ListView.builder(
                    itemCount: locationLogs.length,
                    itemBuilder: (_, i) => Text(
                      locationLogs[i].toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace'),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.explore),
            child: const Text('Lanjut ke jelajah'),
          ),
        ],
      ),
    );
  }
}

class _LocationStatusTile extends StatelessWidget {
  const _LocationStatusTile(
      {required this.status, required this.onOpenSettings});

  final LocationStatus status;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ok = status.isGranted;
    return Card(
      child: ListTile(
        leading: Icon(ok ? Icons.location_on : Icons.location_off,
            color: ok ? AppColors.success : AppColors.danger),
        title: const Text('Status lokasi'),
        subtitle: Text(status.label),
        trailing: ok
            ? null
            : TextButton(
                onPressed: onOpenSettings, child: const Text('Pengaturan')),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.type,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final AppPermissionType type;
  final AppPermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  IconData get _icon {
    switch (type) {
      case AppPermissionType.location:
        return Icons.place;
      case AppPermissionType.bluetooth:
        return Icons.bluetooth;
      case AppPermissionType.camera:
        return Icons.photo_camera;
      case AppPermissionType.notification:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = status.isGranted;
    return Card(
      child: ListTile(
        leading: Icon(_icon, color: AppColors.orange),
        title: Text('Izin ${type.label}'),
        subtitle: Text(status.label),
        trailing: granted
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : status == AppPermissionStatus.permanentlyDenied
                ? TextButton(
                    onPressed: onOpenSettings, child: const Text('Pengaturan'))
                : TextButton(
                    onPressed: onRequest, child: const Text('Izinkan')),
      ),
    );
  }
}
