import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class QuickActionButton extends StatelessWidget {
  const QuickActionButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.lightGrey)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 25, color: AppColors.darkGrey),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
            ]),
          ),
        ),
      );
}
