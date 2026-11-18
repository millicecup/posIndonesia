// lib/features/stamp_making/presentation/stamp_making_screen.dart
// UI19 Visualisasi Pembuatan Perangko (A04, POI P05 di PRD v2): lima tahap step-by-step
// (desain, persiapan cetak, pencetakan, perforasi, hasil akhir) dengan Sebelumnya/Lanjut.
// Nama tahap dari PRD A04; penjelasan tiap tahap diambil dari keyFacts POI (menunggu validasi).

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../providers/providers.dart';

class StampMakingScreen extends ConsumerStatefulWidget {
  const StampMakingScreen({super.key, required this.poiId});

  final String poiId;

  @override
  ConsumerState<StampMakingScreen> createState() => _StampMakingScreenState();
}

class _StampMakingScreenState extends ConsumerState<StampMakingScreen> {
  static const _steps = [
    ('Desain', Icons.brush_outlined),
    ('Persiapan', Icons.layers_outlined),
    ('Cetak', Icons.print_outlined),
    ('Perforasi', Icons.blur_on),
    ('Hasil', Icons.local_post_office_outlined),
  ];
  static const _titles = [
    'Desain',
    'Persiapan cetak',
    'Pencetakan',
    'Perforasi',
    'Hasil akhir',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final poi = ref.watch(poiByIdProvider(widget.poiId)).valueOrNull;
    final facts = poi?.keyFacts ?? const <String>[];
    // keyFacts P05 berformat "Tahap n - Nama: penjelasan"; judul tahap sudah tampil terpisah.
    final text = _index < facts.length
        ? facts[_index].replaceFirst(RegExp(r'^Tahap \d+ - [^:]+:\s*'), '')
        : 'Penjelasan tahap ini menunggu materi yang divalidasi museum.';

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Pembuatan Perangko')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _index = i),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                i == _index ? AppColors.darkGrey : AppColors.white,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  i == _index ? AppColors.darkGrey : AppColors.white,
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      color: i == _index
                                          ? AppColors.white
                                          : AppColors.darkGrey,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_steps[i].$1,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      i == _index ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey(_index),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_steps[_index].$2, size: 96, color: AppColors.orange),
                          const SizedBox(height: 8),
                          Text('Ilustrasi tahap ${_index + 1}',
                              style: const TextStyle(color: AppColors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tahap ${_index + 1}: ${_titles[_index]}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(text),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0 ? null : () => setState(() => _index--),
                      child: const Text('← Sebelumnya'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.darkGrey),
                      onPressed: _index == _steps.length - 1
                          ? () => Navigator.of(context).maybePop()
                          : () => setState(() => _index++),
                      child: Text(_index == _steps.length - 1 ? 'Selesai' : 'Lanjut →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
