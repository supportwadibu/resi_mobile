import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 72, this.color});

  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Lottie.asset(
        'assets/lottie/loader.json',
        fit: BoxFit.contain,
        delegates: color == null
            ? null
            : LottieDelegates(
                values: [
                  ValueDelegate.strokeColor(const ['**'], value: color),
                ],
              ),
        errorBuilder: (_, _, _) => Center(
          child: SizedBox.square(
            dimension: size * 0.4,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class AppLoaderScreen extends StatelessWidget {
  const AppLoaderScreen({super.key, this.backgroundColor = AppColors.white});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const Center(child: AppLoader()),
    );
  }
}
