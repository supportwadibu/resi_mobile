import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.height = 32, this.onMedia = false, super.key});

  final double height;
  final bool onMedia;

  static const _invert = ColorFilter.matrix([
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/resi_logo.png',
      height: height,
      width: height * 1136 / 412,
      semanticLabel: 'Resi',
    );
    final invert = onMedia || Theme.of(context).brightness == Brightness.dark;
    return invert ? ColorFiltered(colorFilter: _invert, child: image) : image;
  }
}
