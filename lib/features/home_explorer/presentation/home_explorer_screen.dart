// lib/features/home_explorer/presentation/home_explorer_screen.dart
// UI03 Home / Explore Museum - BERFUNGSI: daftar 10+ POI dari JSON (bukti PB03).
// TODO(Farella): sesuaikan layout dengan wireframe, banner museum, kartu rekomendasi.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../media_download/presentation/media_download_card.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/poi_card.dart';
import '../../../shared/widgets/progress_badge.dart';
import '../state/home_state.dart';
import '../widgets/quick_action_button.dart';

class HomeExplorerScreen extends ConsumerWidget {
  const HomeExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final validation = ref.watch(datasetValidationProvider);
    final recommended = ref.watch(recommendedNextPoiProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajah Museum'),
        actions: [
          IconButton(
            tooltip: 'Kenali pameran (kamera)',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => context.push(AppRoutes.visionTour),
          ),
          IconButton(
            tooltip: 'Pindai QR',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(AppRoutes.qrScanner),
          ),
          IconButton(
            tooltip: 'Izin & lokasi',
            icon: const Icon(Icons.location_searching),
            onPressed: () => context.push(AppRoutes.permission),
          ),
          if (kDebugMode)
            IconButton(
              tooltip: 'Panel simulasi',
              icon: const Icon(Icons.bug_report),
              onPressed: () => context.push(AppRoutes.simulation),
            ),
        ],
      ),
      body: AsyncValueView<HomeSummary>(
        value: summary,
        onRetry: () => ref.invalidate(poisProvider),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(progressProvider);
            await ref.read(homeSummaryProvider.future);
          },
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Selamat datang di Museum POS Indonesia',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ProgressBadge(
                      visited: data.progress.visitedCount,
                      total: data.pois.length,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickActionButton(
                        icon: Icons.search,
                        label: 'Cari POI',
                        onTap: () => context.push(AppRoutes.poiList)),
                    QuickActionButton(
                        icon: Icons.map,
                        label: 'Peta',
                        onTap: () => context.go(AppRoutes.map)),
                    QuickActionButton(
                        icon: Icons.center_focus_strong,
                        label: 'Kenali',
                        onTap: () => context.push(AppRoutes.visionTour)),
                    QuickActionButton(
                        icon: Icons.tour,
                        label: 'Tur',
                        onTap: () => context.push(AppRoutes.tour)),
                    QuickActionButton(
                        icon: Icons.qr_code,
                        label: 'QR',
                        onTap: () => context.push(AppRoutes.qrScanner)),
                  ],
                ),
              ),
              const MediaDownloadCard(),
              if (recommended != null)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.orangeLight,
                  child: ListTile(
                    leading: const Icon(Icons.recommend, color: AppColors.orange),
                    title: const Text('Rekomendasi berikutnya'),
                    subtitle: Text('${recommended.id}: ${recommended.name}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.poiDetail(recommended.id)),
                  ),
                ),
              // Status validasi dataset (bukti PB03)
              validation.maybeWhen(
                data: (r) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    r.isValid
                        ? 'Dataset valid: ${r.poiCount} POI dimuat dari pois.json '
                            '(${r.warnings.length} catatan validasi)'
                        : 'Dataset bermasalah: ${r.errors.first}',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.isValid ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Semua Koleksi (${data.pois.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final poi in data.pois)
                PoiCard(
                  poi: poi,
                  visited: data.progress.isVisited(poi.id),
                  onTap: () => context.push(AppRoutes.poiDetail(poi.id)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
