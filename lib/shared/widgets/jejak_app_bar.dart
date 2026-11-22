import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Quiet shared header; collection photos and page content carry the visual focus.
class JejakAppBar extends AppBar {
  JejakAppBar(
      {super.key,
      super.title,
      super.leading,
      super.actions,
      super.bottom,
      super.automaticallyImplyLeading})
      : super(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.darkGrey,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light),
        );
}
