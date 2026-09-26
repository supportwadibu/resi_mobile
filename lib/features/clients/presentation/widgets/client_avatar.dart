import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

/// Initiales d'un client, dans un carré bordé.
class ClientAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const ClientAvatar({super.key, required this.initials, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.background,
        border: Border.all(color: t.border),
      ),
      child: Text(
        initials,
        style: context.text.titleSmall!.copyWith(fontSize: size * 0.34),
      ),
    );
  }
}
