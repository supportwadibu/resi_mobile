import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/shared/utils/image_viewer_utils.dart';

class PropertyTopActions extends StatelessWidget {
  final String imagePath;

  const PropertyTopActions({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 48,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildBackButton(context), _buildExpandButton(context)],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.router.pop(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
      ),
    );
  }

  Widget _buildExpandButton(BuildContext context) {
    return GestureDetector(
      onTap: () => ImageViewerUtils.showFullScreenImage(context, imagePath),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const FaIcon(
          FontAwesomeIcons.expand,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }
}
