import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProcessingLogo extends StatelessWidget {
  final double size;

  const ProcessingLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/original_logo_source_fixed.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}
