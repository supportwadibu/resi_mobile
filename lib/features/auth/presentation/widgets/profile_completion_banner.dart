import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_role.dart';
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
    _submitted = _load();
  }

  /// Rôle de la session, `proprio` par défaut.
  ///
  /// Lu par `isRegistered` plutôt qu'en accès direct : ce bandeau est monté par
  /// `HomeScreen`, qui se monte dans des tests de widget ne câblant pas le
  /// conteneur.
  String _currentRole() =>
      sl.isRegistered<SessionRole>() ? sl<SessionRole>().value : 'proprio';

  /// Le dossier de validation est-il déposé ?
  ///
  /// Court-circuité pour le gérant : le dossier est une notion propriétaire,
  /// `GET /proprio/profile` lui répond 403, et le bandeau l'inviterait à
  /// déposer une pièce d'identité qu'aucune route n'accepterait de lui. Le 403
  /// se repliait déjà sur `null` — le bandeau restait donc masqué —, mais
  /// chaque ouverture de l'accueil lui coûtait un appel voué à l'échec.
  Future<bool?> _load() async {
    if (_currentRole() == 'gerant') return true;
    return sl<PropertyManagerService>().isProfileSubmitted();
  }

  Future<void> _openProfile() async {
    await context.router.push(PropertyManagerProfileRoute());

    if (!mounted) return;
    setState(() {
      _submitted = _load();
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
          child: AppCallout(
            icon: LucideIcons.idCard,
            tone: AppAccent.amber,
            title: 'owner_profile.banner_title'.tr(),
            message: 'owner_profile.banner_body'.tr(),
            action: AppButton(
              label: 'owner_profile.banner_action'.tr(),
              size: AppButtonSize.sm,
              trailingIcon: LucideIcons.arrowRight,
              onPressed: _openProfile,
            ),
          ),
        );
      },
    );
  }
}
