import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/jejak_app_bar.dart';
import '../../../shared/widgets/poi_card.dart';
import '../../../shared/widgets/postman_guide.dart';
import '../../media_download/presentation/media_download_card.dart';
import '../state/home_state.dart';
import '../widgets/quick_action_button.dart';

class HomeExplorerScreen extends ConsumerWidget {
  const HomeExplorerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final recommended = ref.watch(recommendedNextPoiProvider).valueOrNull;
    return Scaffold(
      appBar: JejakAppBar(
        title: const Text('Jelajah Museum'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Pilihan lainnya',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: AppRoutes.visionTour,
                  child: Text('Kenali pameran (kamera)')),
              const PopupMenuItem(
                  value: AppRoutes.qrScanner, child: Text('Pindai QR')),
              const PopupMenuItem(
                  value: AppRoutes.permission, child: Text('Izin & lokasi')),
              if (kDebugMode)
                const PopupMenuItem(
                    value: AppRoutes.simulation, child: Text('Panel simulasi')),
            ],
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x15203344),
                        blurRadius: 24,
                        offset: Offset(0, 10))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Image.asset(
                                    'assets/images/logo_jejakpos.png',
                                    width: 170,
                                    height: 58,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.centerLeft,
                                    semanticLabel: 'Logo JejakPOS',
                                  ),
                                  const SizedBox(height: 10),
                                  Text('Selamat datang di Museum POS Indonesia',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 22)),
                                ])),
                            const SizedBox(width: 14),
                            Transform.rotate(
                                angle: 0.07,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                          color: const Color(0xFFE9D4BF),
                                          width: 2)),
                                  child: const PostmanGuide(size: 84),
                                )),
                          ]),
                      const SizedBox(height: 18),
                      Row(children: [
                        const Icon(Icons.flag_outlined,
                            color: Color(0xFF9FD4C6), size: 17),
                        const SizedBox(width: 8),
                        Text(
                            '${data.progress.visitedCount}/${data.pois.length} POI',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: ExcludeSemantics(
                                    child: LinearProgressIndicator(
                                  value: data.pois.isEmpty
                                      ? 0
                                      : data.progress.visitedCount /
                                          data.pois.length,
                                  minHeight: 5,
                                  color: const Color(0xFF91CDBB),
                                  backgroundColor: const Color(0xFF465765),
                                )))),
                      ]),
                      const SizedBox(height: 18),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.tour),
                            icon: const Icon(Icons.route_outlined, size: 23),
                            label: const Text('Mulai tur terpandu'),
                          )),
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    icon: Icons.search_rounded,
                                    label: 'Cari POI',
                                    onTap: () =>
                                        context.push(AppRoutes.poiList))),
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    icon: Icons.map_outlined,
                                    label: 'Peta',
                                    onTap: () => context.go(AppRoutes.map))),
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    icon: Icons.center_focus_strong,
                                    label: 'Kenali',
                                    onTap: () =>
                                        context.push(AppRoutes.visionTour))),
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    icon: Icons.qr_code_scanner,
                                    label: 'Pindai QR',
                                    onTap: () =>
                                        context.push(AppRoutes.qrScanner))),
                          ],
                        )),
              ),
              const SizedBox(height: 12),
              const MediaDownloadCard(),
              if (recommended != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Material(
                    color: const Color(0xFFEAF2EE),
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: const Icon(Icons.near_me_outlined,
                          color: AppColors.teal),
                      title: const Text('Rekomendasi berikutnya',
                          style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      subtitle: Text('${recommended.id}: ${recommended.name}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.5)),
                      trailing: const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.teal, size: 20),
                      onTap: () =>
                          context.push(AppRoutes.poiDetail(recommended.id)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('Semua Koleksi (${data.pois.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final poi in data.pois)
                PoiCard(
                    poi: poi,
                    visited: data.progress.isVisited(poi.id),
                    onTap: () => context.push(AppRoutes.poiDetail(poi.id))),
            ],
          ),
        ),
      ),
    );
  }
}
