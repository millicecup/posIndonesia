// Maskot prangko JejakPOS, dipakai bersama pada onboarding dan pemandu tur.
import 'package:flutter/material.dart';

class PostmanGuide extends StatelessWidget {
  const PostmanGuide({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 1.15,
        child: Image.asset(
          'assets/images/maskot_prangko.jpg',
          fit: BoxFit.contain,
          semanticLabel:
              'Maskot prangko JejakPOS memakai topi dan tas petugas pos',
        ),
      );
}
