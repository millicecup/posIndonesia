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
import '../../../shared/widgets/tutorial_navigation_scope.dart';
import '../../media_download/presentation/media_download_card.dart';
import '../state/home_state.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/explore_tutorial.dart';

class HomeExplorerScreen extends ConsumerStatefulWidget {
  const HomeExplorerScreen({super.key});
  @override
  ConsumerState<HomeExplorerScreen> createState() => _HomeExplorerScreenState();
}

class _HomeExplorerScreenState extends ConsumerState<HomeExplorerScreen> {
  final _tourTarget = GlobalKey();
  final _qrTarget = GlobalKey();
  final _collectionCardTarget = GlobalKey();
  final _searchTarget = GlobalKey();
  final _mapTarget = GlobalKey();
  final _recognizeTarget = GlobalKey();
  final _helpTarget = GlobalKey();
  bool _tutorialScheduled = false;
  bool _tutorialOpen = false;

  Future<void> _showTutorial() async {
    if (_tutorialOpen || !mounted) return;
    _tutorialOpen = true;
    // Remember showing it, including Skip; replay remains available in the header.
    await ref
        .read(sharedPreferencesProvider)
        .setBool(exploreTutorialSeenKey, true);
    if (!mounted) return;
    final navigation = TutorialNavigationScope.maybeOf(context);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => ExploreTutorial(steps: [
        TutorialStep(_tourTarget, 'Mulai dari tur terpandu',
            'Ikuti pemandu untuk menjelajahi koleksi museum. Kamu juga bebas membuka koleksi sendiri.'),
        TutorialStep(_searchTarget, 'Cari koleksi yang kamu inginkan',
            'Ketuk Cari POI untuk mencari koleksi berdasarkan namanya. POI adalah titik koleksi yang bisa kamu jelajahi.'),
        TutorialStep(_mapTarget, 'Lihat lokasi koleksi',
            'Buka Peta untuk melihat denah museum. Pilih titik koleksi, lalu ketuk Detail atau Arahkan.'),
        TutorialStep(_recognizeTarget, 'Kenali pameran lewat kamera',
            'Ketuk Kenali, lalu arahkan kamera ke pameran yang didukung untuk mengenali koleksinya.'),
        TutorialStep(_qrTarget, 'Pindai QR di dekat koleksi',
            'Arahkan kamera ke QR koleksi untuk membuka informasinya. Setelah selesai, kamu bisa memindai koleksi berikutnya.'),
        TutorialStep(_collectionCardTarget, 'Buka cerita koleksi',
            'Ketuk kartu koleksi untuk membaca cerita, melihat foto, dan mencoba aktivitasnya. Setelah selesai, ambil prangko untuk mengisi album.'),
        if (navigation != null) ...[
          TutorialStep(navigation.explore, 'Kembali ke Jelajah',
              'Tab Jelajah membawamu kembali ke halaman utama, daftar koleksi, dan rekomendasi berikutnya.'),
          TutorialStep(navigation.map, 'Denah selalu mudah dijangkau',
              'Tab Peta membuka denah yang sama dengan tombol Peta di atas. Gunakan akses ini saat berpindah koleksi.'),
          TutorialStep(navigation.album, 'Prangkomu tersimpan di Album',
              'Setelah membaca koleksi, tekan “Selesai & ambil prangko”. Buka Album untuk melihat prangko yang sudah kamu kumpulkan.'),
          TutorialStep(navigation.progress, 'Pantau perjalananmu',
              'Tab Progres menampilkan perkembangan kunjunganmu. POI yang dikunjungi dan prangko yang diambil dihitung terpisah.'),
        ],
        TutorialStep(_helpTarget, 'Butuh panduan lagi?',
            'Ketuk tombol bantuan ini kapan saja untuk mengulang tutorial. Selamat menjelajah Museum Pos Indonesia!'),
      ]),
    );
    _tutorialOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(homeSummaryProvider);
    final recommended = ref.watch(recommendedNextPoiProvider).valueOrNull;
    if (!_tutorialScheduled &&
        summary.hasValue &&
        GoRouterState.of(context).uri.path == AppRoutes.explore) {
      _tutorialScheduled = true;
      if (!(ref
              .read(sharedPreferencesProvider)
              .getBool(exploreTutorialSeenKey) ??
          false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showTutorial();
        });
      }
    }
    return Scaffold(
      appBar: JejakAppBar(
        title: const Text('Jelajah museum'),
        actions: [
          IconButton(
            key: _helpTarget,
            tooltip: 'Tutorial penggunaan',
            onPressed: summary.hasValue ? _showTutorial : null,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Pilihan lainnya',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: AppRoutes.permission, child: Text('Izin dan lokasi')),
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
                                  Text('Selamat datang di Museum Pos Indonesia',
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
                        Flexible(
                            child: Text(
                                '${data.progress.visitedCount}/${data.pois.length} POI dikunjungi',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600))),
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
                      const SizedBox(height: 6),
                      Text('${data.progress.stampCount} prangko terkumpul',
                          style: const TextStyle(
                              color: Color(0xFFCEE0DA), fontSize: 13)),
                      const SizedBox(height: 18),
                      SizedBox(
                          key: _tourTarget,
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
                                    key: _searchTarget,
                                    icon: Icons.search_rounded,
                                    label: 'Cari POI',
                                    onTap: () =>
                                        context.push(AppRoutes.poiList))),
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    key: _mapTarget,
                                    icon: Icons.map_outlined,
                                    label: 'Peta',
                                    onTap: () => context.go(AppRoutes.map))),
                            SizedBox(
                                width: (constraints.maxWidth - 30) / 4,
                                child: QuickActionButton(
                                    key: _recognizeTarget,
                                    icon: Icons.center_focus_strong,
                                    label: 'Kenali',
                                    onTap: () =>
                                        context.push(AppRoutes.visionTour))),
                            SizedBox(
                                key: _qrTarget,
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
                    child: InkWell(
                      onTap: () =>
                          context.push(AppRoutes.poiDetail(recommended.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.near_me_outlined,
                                color: AppColors.teal),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rekomendasi berikutnya',
                                    style: TextStyle(
                                        color: AppColors.teal,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4)),
                                const SizedBox(height: 4),
                                Text('${recommended.id}: ${recommended.name}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4)),
                              ],
                            )),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.teal, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('Semua koleksi (${data.pois.length})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (var i = 0; i < data.pois.length; i++)
                PoiCard(
                    key: i == 0 ? _collectionCardTarget : null,
                    poi: data.pois[i],
                    visited: data.progress.isVisited(data.pois[i].id),
                    onTap: () =>
                        context.push(AppRoutes.poiDetail(data.pois[i].id))),
            ],
          ),
        ),
      ),
    );
  }
}
