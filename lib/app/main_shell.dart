// lib/app/main_shell.dart
// Bottom navigation 4 tab: Jelajah, Peta, Album, Progres (PIC: Farella).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/voice_guide/presentation/voice_guide_bar.dart';
import '../shared/widgets/tutorial_navigation_scope.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _targets = TutorialNavigationTargets();

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return TutorialNavigationScope(
        targets: _targets,
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VoiceGuideBar(),
              NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  // Tap tab aktif -> kembali ke halaman awal tab.
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: [
                  NavigationDestination(
                      key: _targets.explore,
                      icon: const Icon(Icons.explore_outlined),
                      selectedIcon: const Icon(Icons.explore),
                      label: 'Jelajah'),
                  NavigationDestination(
                      key: _targets.map,
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map),
                      label: 'Peta'),
                  NavigationDestination(
                      key: _targets.album,
                      icon: const Icon(Icons.collections_bookmark_outlined),
                      selectedIcon: const Icon(Icons.collections_bookmark),
                      label: 'Album'),
                  NavigationDestination(
                      key: _targets.progress,
                      icon: const Icon(Icons.flag_outlined),
                      selectedIcon: const Icon(Icons.flag),
                      label: 'Progres'),
                ],
              ),
            ],
          ),
        ));
  }
}
