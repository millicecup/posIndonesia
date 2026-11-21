import 'package:flutter/material.dart';

class TutorialNavigationTargets {
  final explore = GlobalKey();
  final map = GlobalKey();
  final album = GlobalKey();
  final progress = GlobalKey();
}

/// Lets the home walkthrough highlight the shell's actual navigation controls.
class TutorialNavigationScope extends InheritedWidget {
  const TutorialNavigationScope(
      {super.key, required this.targets, required super.child});
  final TutorialNavigationTargets targets;
  static TutorialNavigationTargets? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TutorialNavigationScope>()
      ?.targets;
  @override
  bool updateShouldNotify(TutorialNavigationScope oldWidget) =>
      targets != oldWidget.targets;
}
