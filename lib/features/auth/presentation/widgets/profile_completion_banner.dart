import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/property_manager_service.dart';

class ProfileCompletionBanner extends StatefulWidget {
  const ProfileCompletionBanner({super.key});

  @override
  State<ProfileCompletionBanner> createState() =>
      _ProfileCompletionBannerState();
}

class _ProfileCompletionBannerState extends State<ProfileCompletionBanner> {

  late Future<bool?> _submitted;

  @override
  void initState() {
    super.initState();
    _submitted = sl<PropertyManagerService>().isProfileSubmitted();
  }

  Future<void> _openProfile() async {
    await context.router.push(PropertyManagerProfileRoute());

    if (!mounted) return;
    setState(() {
      _submitted = sl<PropertyManagerService>().isProfileSubmitted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: _submitted,
      builder: (context, snapshot) {
        if (snapshot.data != false) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.idCard,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finalisez votre inscription',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Transmettez votre pièce d’identité pour éviter la '
                            'suspension de votre compte.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.grey600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
