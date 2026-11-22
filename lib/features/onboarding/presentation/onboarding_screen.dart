// lib/features/onboarding/presentation/onboarding_screen.dart
// UI01 Welcome / Onboarding: 3 slide Explore, Discover, Collect (PRD 1.3, Gambar 5.1 kiri).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/postman_guide.dart';
import '../state/onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      'Explore',
      Icons.map_outlined,
      'Jelajahi denah museum. Saat kamu mendekati koleksi, informasinya muncul otomatis.'
    ),
    (
      'Discover',
      Icons.headphones_outlined,
      'Pahami sejarah lewat ringkasan, fakta penting, gambar, narasi audio, dan pemandu virtual.'
    ),
    (
      'Collect',
      Icons.local_post_office_outlined,
      'Kumpulkan prangko digital, berfoto dengan seragam petugas pos, dan dapatkan cap kunjunganmu.'
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(AppRoutes.permission);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  physics: const PageScrollPhysics(),
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _welcome(context),
                    for (final s in _slides) _slide(context, s.$1, s.$2, s.$3),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.darkGrey
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                child: SizedBox(
                    width: double.infinity,
                    child: Text(last ? 'Mulai menjelajah' : 'Lanjut',
                        textAlign: TextAlign.center)),
              ),
              if (!last)
                TextButton(
                    onPressed: _finish, child: const Text('Lewati pengantar')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readingPage(Widget child) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: child)),
          ),
        ),
      );

  Widget _welcome(BuildContext context) => _readingPage(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_jejakpos.png',
              width: 240,
              height: 82,
              fit: BoxFit.contain,
              semanticLabel: 'Logo JejakPOS'),
          SizedBox(height: MediaQuery.sizeOf(context).height < 700 ? 12 : 22),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: PostmanGuide(
                size: MediaQuery.sizeOf(context).height < 700 ? 130 : 180),
          ),
          const SizedBox(height: 24),
          Text('Museum Pos Indonesia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(AppConstants.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.grey)),
        ],
      ));

  Widget _slide(
          BuildContext context, String title, IconData icon, String text) =>
      _readingPage(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_jejakpos.png',
              width: 150, height: 52, fit: BoxFit.contain),
          const SizedBox(height: 32),
          SizedBox(
            height: MediaQuery.sizeOf(context).height < 700 ? 130 : 200,
            child: Center(
                child: Icon(icon,
                    size: 100,
                    color: title == 'Discover'
                        ? AppColors.teal
                        : AppColors.orange)),
          ),
          const SizedBox(height: 28),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ));
}
