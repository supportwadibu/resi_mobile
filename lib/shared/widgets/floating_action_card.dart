import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';

class FloatingActionCard extends StatelessWidget {
  const FloatingActionCard({
    required this.features,
    required this.onSelect,
    required this.onDismiss,
    super.key,
  });

  final List<FloatingFeature> features;
  final void Function(String action) onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.black.withOpacity(0.75),
                AppColors.black.withOpacity(0.50),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header

              // Items
              ...features.map(
                (f) => _FeatureButton(
                  feature: f,
                  onTap: () => onSelect(f.action),
                  isLast: f == features.last,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.feature,
    required this.onTap,
    required this.isLast,
  });

  final FloatingFeature feature;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FaIcon(
                        feature.icon,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),  
                const SizedBox(width: 12),
                Text(
                  feature.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(color: Colors.white10, height: 1, indent: 16),
      ],
    );
  }
}

class FloatingFeature {
  const FloatingFeature({
    required this.icon,
    required this.label,
    required this.action,
  });

  final FaIconData icon;
  final String label;
  final String action;
}
