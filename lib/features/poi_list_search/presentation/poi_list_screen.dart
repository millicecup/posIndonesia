// lib/features/poi_list_search/presentation/poi_list_screen.dart
// UI04 Cari koleksi & Pencarian POI.
// TODO(Denaya): kelompokkan daftar per kategori (section header), empty state sesuai wireframe.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/poi_card.dart';
import '../../../shared/widgets/search_bar_field.dart';
import '../state/poi_search_controller.dart';

class PoiListScreen extends ConsumerStatefulWidget {
  const PoiListScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<PoiListScreen> createState() => _PoiListScreenState();
}

class _PoiListScreenState extends ConsumerState<PoiListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      // Set setelah frame pertama agar tidak mengubah provider saat build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryIdProvider.notifier).state = widget.initialCategoryId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(poiCategoriesProvider).valueOrNull ?? const <PoiCategory>[];
    final selectedId = ref.watch(selectedCategoryIdProvider);
    final results = ref.watch(poiSearchResultsProvider);
    final visited =
        ref.watch(progressProvider).valueOrNull?.visitedPoiIds ?? const <String>[];

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Cari koleksi')),
      body: Column(
        children: [
          SearchBarField(
            onChanged: (q) => ref.read(poiSearchQueryProvider.notifier).state = q,
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CategoryChip(
                    label: 'Semua',
                    selected: selectedId == null,
                    onSelected: (_) =>
                        ref.read(selectedCategoryIdProvider.notifier).state = null,
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CategoryChip(
                      label: c.label,
                      selected: selectedId == c.id,
                      onSelected: (sel) => ref
                          .read(selectedCategoryIdProvider.notifier)
                          .state = sel ? c.id : null,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Poi>>(
              value: results,
              data: (pois) => pois.isEmpty
                  ? const Center(child: Text('Tidak ada POI yang cocok.'))
                  : ListView.builder(
                      itemCount: pois.length,
                      itemBuilder: (_, i) => PoiCard(
                        poi: pois[i],
                        visited: visited.contains(pois[i].id),
                        onTap: () => context.push(AppRoutes.poiDetail(pois[i].id)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
