// lib/features/map_navigation/presentation/museum_welcome_dialog.dart
// Trigger "masuk area museum" (DF-01). Muncul otomatis sekali per kunjungan saat GPS
// mendeteksi pengguna memasuki geofence museum, lalu menawarkan langkah berikutnya.
// Di dalam gedung GPS terlalu kasar untuk memicu POI (jarak antar-POI 1-10 m), jadi
// sambutan ini mengarahkan pengguna ke Kenali (kamera), QR, atau tur terpandu.

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/postman_guide.dart';

enum MuseumWelcomeAction { tour, recognize, qr, later }

Future<MuseumWelcomeAction?> showMuseumWelcomeDialog(BuildContext context) =>
    showDialog<MuseumWelcomeAction>(
      context: context,
      builder: (ctx) => const MuseumWelcomeDialog(),
    );

class MuseumWelcomeDialog extends StatelessWidget {
  const MuseumWelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    void close(MuseumWelcomeAction a) => Navigator.of(context).pop(a);
    return AlertDialog(
      key: const Key('museum-welcome'),
      scrollable: true,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(4)),
            child: const Text('Kamu tiba di museum',
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(height: 12),
          const PostmanGuide(size: 96),
          const SizedBox(height: 8),
          Text('Selamat datang di Museum Pos Indonesia!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Lokasimu sudah terdeteksi di area museum. Mulai tur terpandu, '
            'arahkan kamera ke pameran dengan Kenali, atau pindai QR di '
            'penanda koleksi untuk membuka ceritanya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.4),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => close(MuseumWelcomeAction.tour),
                icon: const Icon(Icons.route_outlined, size: 20),
                label: const Text('Mulai tur terpandu'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => close(MuseumWelcomeAction.recognize),
                icon: const Icon(Icons.center_focus_strong, size: 20),
                label: const Text('Kenali pameran'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => close(MuseumWelcomeAction.qr),
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Pindai QR koleksi'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => close(MuseumWelcomeAction.later),
                child: const Text('Nanti saja'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
