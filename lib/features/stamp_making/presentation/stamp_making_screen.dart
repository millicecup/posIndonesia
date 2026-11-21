import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/jejak_app_bar.dart';

// Educational overview, independent of P05 keyFacts.
// Provenance: assets/images/stamp_making/credits.json.
const stampMakingSteps = [
  (
    title: 'Desain',
    image: 'design.jpg',
    text:
        'Perjalanan prangko dimulai dari sebuah rancangan. Gambar, tulisan, dan nilai nominal disusun agar pesannya terbaca pada bidang yang kecil. Rancangan ini menjadi acuan untuk menyiapkan cetakan.',
    caption:
        'Contoh desain pada cetak uji prangko Benjamin Franklin, Amerika Serikat, 1870.',
    credit: 'US Post Office / Wikimedia Commons. Domain publik.'
  ),
  (
    title: 'Persiapan cetak',
    image: 'proof.jpg',
    text:
        'Desain dipindahkan ke media cetak sesuai teknik yang digunakan, misalnya pelat pada cetak offset atau intaglio. Cetak uji membantu memeriksa detail dan warna sebelum pencetakan dalam jumlah besar.',
    caption:
        'Cetak uji prangko Abraham Lincoln, Amerika Serikat, 1890. Gambar ini memperlihatkan hasil uji, bukan pelat cetaknya.',
    credit: 'US Post Office / Wikimedia Commons. Domain publik.'
  ),
  (
    title: 'Pencetakan',
    image: 'printing.jpg',
    text:
        'Mesin memindahkan tinta ke kertas sehingga desain muncul berulang dalam satu lembar. Tekniknya dapat berbeda; cetak offset memakai beberapa warna tinta, sedangkan intaglio memakai cetakan berukir. Hasil cetak kemudian diperiksa.',
    caption:
        'Pekerja mengambil lembar prangko dari mesin cetak di Bureau of Engraving and Printing, Amerika Serikat, 1889–1890.',
    credit: 'Frances Benjamin Johnston / Library of Congress. Domain publik.'
  ),
  (
    title: 'Perforasi',
    image: 'perforation.jpg',
    text:
        'Pada prangko berperforasi, deretan lubang kecil dibuat di antara prangko agar setiap keping mudah dipisahkan. Prangko berperekat mandiri dapat memakai potongan pisau cetak, sehingga tidak semua prangko melalui perforasi yang sama.',
    caption:
        'Pekerja melubangi lembar prangko di Bureau of Engraving and Printing, Amerika Serikat, sekitar 1895.',
    credit:
        'Frances Benjamin Johnston / Library of Congress, melalui Wikimedia Commons. Domain publik.'
  ),
  (
    title: 'Hasil akhir',
    image: 'finished.jpg',
    text:
        'Lembaran yang sudah selesai diproses dipotong menjadi bagian yang lebih kecil untuk penjualan. Dari sebuah rancangan, prangko kini siap digunakan sebagai bukti pembayaran biaya pos atau disimpan sebagai koleksi.',
    caption:
        'Contoh prangko jadi: Abraham Lincoln, 4 sen, Amerika Serikat, terbitan 1890.',
    credit: 'US Post Office / Wikimedia Commons. Domain publik.'
  ),
];

class StampMakingScreen extends StatefulWidget {
  const StampMakingScreen({super.key, required this.poiId});
  final String poiId;
  @override
  State<StampMakingScreen> createState() => _StampMakingScreenState();
}

class _StampMakingScreenState extends State<StampMakingScreen> {
  int _index = 0;
  final _scroll = ScrollController();
  void _select(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = stampMakingSteps[_index];
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: JejakAppBar(title: const Text('Pembuatan prangko')),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              for (var i = 0; i < stampMakingSteps.length; i++)
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Semantics(
                          selected: i == _index,
                          child: TextButton(
                            onPressed: () => _select(i),
                            style: TextButton.styleFrom(
                                backgroundColor: i == _index
                                    ? AppColors.teal
                                    : AppColors.lightGrey,
                                foregroundColor: i == _index
                                    ? AppColors.white
                                    : AppColors.darkGrey,
                                minimumSize: const Size(44, 44),
                                padding: EdgeInsets.zero),
                            child: Text('${i + 1}',
                                semanticsLabel:
                                    'Tahap ${i + 1}: ${stampMakingSteps[i].title}'),
                          ),
                        ))),
            ])),
        Expanded(
            child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tahap ${_index + 1} dari 5',
                      style: theme.labelLarge?.copyWith(color: AppColors.teal)),
                  const SizedBox(height: 4),
                  Text(step.title, style: theme.headlineMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                      height: MediaQuery.sizeOf(context).height * .34,
                      child: Image.asset(
                          'assets/images/stamp_making/${step.image}',
                          fit: BoxFit.contain,
                          semanticLabel: step.caption)),
                  const SizedBox(height: 12),
                  Text(step.caption, style: theme.bodySmall),
                  const SizedBox(height: 20),
                  Text(step.text, style: theme.bodyLarge),
                  const SizedBox(height: 20),
                  const Text(
                      'Alur ini diringkas menjadi lima tahap untuk membantu belajar. Proses sebenarnya dapat berbeda menurut jenis prangko dan teknik cetaknya.'),
                  const SizedBox(height: 16),
                  Text(step.credit, style: theme.bodySmall),
                ]),
          )),
        )),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _index == 0 ? null : () => _select(_index - 1),
                      child: const Text('Sebelumnya'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: _index == stampMakingSteps.length - 1
                          ? () => Navigator.of(context).maybePop()
                          : () => _select(_index + 1),
                      child: Text(_index == stampMakingSteps.length - 1
                          ? 'Selesai'
                          : 'Lanjut'))),
            ])),
      ])),
    );
  }
}
