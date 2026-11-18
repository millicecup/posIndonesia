import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Shared header so every screen uses the same JejakPOS gradient.
class JejakAppBar extends AppBar {
  JejakAppBar({
    super.key,
    super.title,
    super.leading,
    super.actions,
    super.bottom,
    super.automaticallyImplyLeading,
  }) : super(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          flexibleSpace: const SizedBox.expand(
              child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC64B18), Color(0xFFEF782B)],
              ),
            ),
          )),
        );
}
