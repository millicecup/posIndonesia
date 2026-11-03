// lib/shared/widgets/category_chip.dart
// Chip kategori; bisa tampilan saja (dense) atau bisa dipilih (filter UI04).

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense || onSelected == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orangeLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
        ),
      );
    }
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.orange,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.darkGrey),
    );
  }
}
