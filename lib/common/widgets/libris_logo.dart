import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';

class LibrisLogo extends StatelessWidget {
  final double size;

  const LibrisLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l10n('Libris logosu', 'Libris logo'),
      image: true,
      child: Image.asset(
        'assets/branding/libris-icon-256.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
