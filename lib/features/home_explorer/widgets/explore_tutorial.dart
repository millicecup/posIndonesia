import 'package:flutter/material.dart';
import '../../../app/theme.dart';

const exploreTutorialSeenKey = 'explore_tutorial_seen_v1';

class TutorialStep {
  const TutorialStep(this.target, this.title, this.description);
  final GlobalKey target;
  final String title;
  final String description;
}

/// Modal walkthrough: blocks accidental actions while keeping the real UI visible.
class ExploreTutorial extends StatefulWidget {
  const ExploreTutorial({super.key, required this.steps});
  final List<TutorialStep> steps;

  @override
  State<ExploreTutorial> createState() => _ExploreTutorialState();
}

class _ExploreTutorialState extends State<ExploreTutorial>
    with WidgetsBindingObserver {
  int _index = 0;
  Rect? _target;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _select(0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _select(_index);
    });
  }

  Future<void> _select(int index) async {
    if (!mounted) return;
    setState(() {
      _index = index;
      _moving = true;
      _target = null;
    });
    final targetContext = widget.steps[index].target.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(targetContext,
          alignment: .05, duration: const Duration(milliseconds: 240));
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final box = widget.steps[index].target.currentContext?.findRenderObject();
    final overlay = context.findRenderObject();
    setState(() {
      _moving = false;
      if (box is RenderBox && box.hasSize && overlay is RenderBox) {
        _target = ((box.localToGlobal(Offset.zero) -
                    overlay.localToGlobal(Offset.zero)) &
                box.size)
            .inflate(7);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    return Material(
      type: MaterialType.transparency,
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: _SpotlightPainter(_target)),
        if (_target != null)
          LayoutBuilder(builder: (context, constraints) {
            final safe = MediaQuery.paddingOf(context);
            final target = _target!;
            final belowSpace =
                constraints.maxHeight - safe.bottom - 16 - target.bottom;
            final aboveSpace = target.top - safe.top - 16;
            final below = belowSpace >= 260 || belowSpace >= aboveSpace;
            final width = (constraints.maxWidth - 32).clamp(0.0, 360.0);
            final left = (target.center.dx - width / 2)
                .clamp(16.0, constraints.maxWidth - width - 16);
            return CustomSingleChildLayout(
              delegate: _CoachPosition(target, below, width, left, safe),
              child: CustomPaint(
                painter: _BubblePointer(
                    (target.center.dx - left).clamp(24.0, width - 24), below),
                child: Padding(
                  padding: EdgeInsets.only(
                      top: below ? 12 : 0, bottom: below ? 0 : 12),
                  child: Material(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 12,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      'Panduan ${_index + 1}/${widget.steps.length}',
                                      style: const TextStyle(
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.w700))),
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Lewati')),
                            ]),
                            Semantics(
                                header: true,
                                liveRegion: true,
                                child: Text(step.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium)),
                            const SizedBox(height: 8),
                            Text(step.description,
                                style:
                                    const TextStyle(fontSize: 14, height: 1.5)),
                            const SizedBox(height: 20),
                            Row(children: [
                              if (_index > 0) ...[
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: _moving
                                            ? null
                                            : () => _select(_index - 1),
                                        child: const Text('Kembali'))),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                  child: FilledButton(
                                onPressed: _moving
                                    ? null
                                    : () {
                                        if (_index == widget.steps.length - 1) {
                                          Navigator.of(context).pop();
                                        } else {
                                          _select(_index + 1);
                                        }
                                      },
                                child: Text(_index == widget.steps.length - 1
                                    ? 'Mengerti'
                                    : 'Lanjut'),
                              )),
                            ]),
                          ]),
                    ),
                  ),
                ),
              ),
            );
          }),
      ]),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.target);
  final Rect? target;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
          RRect.fromRectAndRadius(target!, const Radius.circular(18)));
    }
    canvas.drawPath(path, Paint()..color = const Color(0xB5203344));
    if (target != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(target!, const Radius.circular(18)),
          Paint()
            ..color = AppColors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      target != oldDelegate.target;
}

class _CoachPosition extends SingleChildLayoutDelegate {
  const _CoachPosition(
      this.target, this.below, this.width, this.left, this.safe);
  final Rect target;
  final bool below;
  final double width;
  final double left;
  final EdgeInsets safe;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = below
        ? constraints.maxHeight - safe.bottom - 16 - target.bottom - 4
        : target.top - safe.top - 20;
    return BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight:
            available.clamp(80.0, constraints.maxHeight - safe.vertical - 32));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
      left, below ? target.bottom + 4 : target.top - childSize.height - 4);
  @override
  bool shouldRelayout(_CoachPosition old) =>
      target != old.target ||
      below != old.below ||
      width != old.width ||
      safe != old.safe;
}

class _BubblePointer extends CustomPainter {
  const _BubblePointer(this.x, this.below);
  final double x;
  final bool below;
  @override
  void paint(Canvas canvas, Size size) {
    final edge = below ? 12.0 : size.height - 12;
    final tip = below ? 0.0 : size.height;
    final path = Path()
      ..moveTo(x - 11, edge)
      ..lineTo(x, tip)
      ..lineTo(x + 11, edge)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.cream);
  }

  @override
  bool shouldRepaint(_BubblePointer old) => x != old.x || below != old.below;
}
