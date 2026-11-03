// lib/shared/widgets/progress_badge.dart
// Lencana progres kunjungan "3/13 POI".

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ProgressBadge extends StatelessWidget {
  const ProgressBadge({
    super.key,
    required this.visited,
    required this.total,
    this.label = 'POI',
  });

  final int visited;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : visited / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 3,
              backgroundColor: AppColors.lightGrey,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$visited/$total $label',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }
}
