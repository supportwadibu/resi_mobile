import 'package:easy_localization/easy_localization.dart';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/home/presentation/widgets/home/home_greeting.dart';
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
  final _auth = sl<AuthService>();

  /// Le nom retenu à la connexion s'affiche aussitôt, sans requête —
  /// l'accueil s'affiche aussi hors ligne.
  late String _name = _auth.cachedAccountName()?.trim() ?? '';

  /// Tirées une fois : un nouveau rendu ne doit pas changer les mots sous
  /// les yeux de l'utilisateur.
  late final String _salutation;
  late final String _tagline;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _salutation = HomeGreeting.salutation(DateTime.now(), random);
    _tagline = HomeGreeting.tagline(random);
    _refreshName();
  }

  Future<void> _refreshName() async {
    final fresh = (await _auth.refreshAccountName())?.trim();
    if (!mounted || fresh == null || fresh.isEmpty || fresh == _name) return;
    setState(() => _name = fresh);
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = _name;
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
                      : Text(_initials(name), style: context.text.titleSmall),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_salutation, style: context.text.bodySmall),
                      Text(
                        name.isEmpty ? _tagline : name,
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
          label: 'common.contact_support'.tr(),
          bordered: true,
          onPressed: () => showSupportContactSheet(context),
        ),
      ],
    );
  }
}
