import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/storage/local_storage.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/auth/data/models/property_manager_model.dart';
import 'package:resi_africa/features/support/presentation/widgets/support_contact_sheet.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';

/// En-tête de l'accueil : initiales et nom du compte, qui mènent au profil,
/// et accès au support.
class TopBarWidget extends StatefulWidget {
  const TopBarWidget({super.key});

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  /// Lu une fois : le compte enregistré à la connexion suffit à saluer, sans
  /// requête — l'accueil s'affiche aussi hors ligne.
  late final Future<PropertyManagerModel?> _account = sl<LocalStorage>()
      .getPropertyManager();

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<PropertyManagerModel?>(
      future: _account,
      builder: (context, snapshot) {
        final name = snapshot.data?.name.trim() ?? '';
        return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.pushRoute(const ProfileRoute()),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.background,
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: t.border),
                      ),
                      child: name.isEmpty
                          ? Icon(LucideIcons.user, size: 18, color: t.muted)
                          : Text(
                              _initials(name),
                              style: context.text.titleSmall,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bonjour', style: context.text.bodySmall),
                          Text(
                            name.isEmpty ? 'Bienvenue' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: LucideIcons.headset,
              label: 'Contacter le support',
              bordered: true,
              onPressed: () => showSupportContactSheet(context),
            ),
          ],
        );
      },
    );
  }
}
