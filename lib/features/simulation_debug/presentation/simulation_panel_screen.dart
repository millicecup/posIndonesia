// lib/features/simulation_debug/presentation/simulation_panel_screen.dart
// Panel debug emulator: "pindah ke POI Pxx", beacon palsu, reset sesi trigger.
// Hanya untuk pengujian (emulator tidak punya BLE & kamera asli). PIC: Matilda/Firda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/trigger_engine.dart';

class SimulationPanelScreen extends ConsumerWidget {
  const SimulationPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(simulationModeProvider);
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];
    final sim = ref.watch(simulationServiceProvider);
    final engine = ref.watch(triggerEngineProvider);
    final statuses = ref.watch(poiProximityProvider).valueOrNull ?? engine.statuses;
    final position = ref.watch(positionStreamProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Simulasi Emulator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Mode simulasi'),
            subtitle: Text(enabled
                ? 'Posisi & beacon dari SimulationService'
                : 'Pakai GPS (Extended Controls > Location di emulator)'),
            value: enabled,
            onChanged: (v) => ref.read(simulationModeProvider.notifier).setEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('Posisi aktif'),
            subtitle: Text(position?.toString() ?? 'belum ada'),
          ),
          ListTile(
            leading: Icon(engine.isInsideMuseum ? Icons.museum : Icons.wrong_location),
            title: Text(engine.isInsideMuseum
                ? 'Di dalam area museum (geofence placeholder)'
                : 'Di luar area museum'),
            subtitle: Text('Terpicu sesi ini: ${engine.triggeredThisSession.join(', ')}'),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: enabled ? sim.moveToMuseumEntrance : null,
                child: const Text('Ke pintu masuk'),
              ),
              OutlinedButton(
                onPressed: () async {
                  // Sama dengan "Akhiri kunjungan": status terpicu dihapus, progres tetap.
                  await ref.read(visitSessionProvider).endVisit();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesi trigger direset')));
                  }
                },
                child: const Text('Reset sesi trigger'),
              ),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.qrScanner),
                child: const Text('Input QR manual'),
              ),
            ],
          ),
          if (!enabled)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aktifkan mode simulasi untuk memakai tombol "Pindah" dan "Beacon".',
                  style: TextStyle(color: AppColors.warning)),
            ),
          const Divider(height: 24),
          for (final poi in pois)
            Card(
              child: ListTile(
                title: Text('${poi.id} · ${poi.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_statusText(statuses[poi.id])),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Pindah ke ${poi.id}',
                      icon: const Icon(Icons.place),
                      onPressed: enabled ? () => sim.moveToPoi(poi) : null,
                    ),
                    IconButton(
                      tooltip: 'Kirim beacon ${poi.beaconId}',
                      icon: const Icon(Icons.bluetooth_searching),
                      onPressed: enabled ? () => sim.emitBeacon(poi.beaconId) : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusText(PoiProximityStatus? s) {
    if (s == null) return 'outside';
    final d = s.distanceMeters;
    return '${s.proximity.name}${d != null ? ' · ${d.toStringAsFixed(1)} m' : ''}';
  }
}
