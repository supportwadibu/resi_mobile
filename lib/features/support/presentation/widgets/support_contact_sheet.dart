import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/config/app_config.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/utils/launcher_helper.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

Future<void> showSupportContactSheet(
  BuildContext context, {
  String? visitorName,
  String? visitorEmail,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => _SupportContactSheet(
      visitorName: visitorName,
      visitorEmail: visitorEmail,
    ),
  );
}

class _SupportContactSheet extends StatelessWidget {
  const _SupportContactSheet({this.visitorName, this.visitorEmail});

  final String? visitorName;
  final String? visitorEmail;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppSheet(
      title: 'Besoin d\'aide ?',
      description: 'Choisissez comment nous joindre',
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (AppConfig.isSupportChatEnabled)
            // Le canal le plus rapide, en tête et marqué : guider vers lui
            // sans masquer les autres.
            AppSheetAction(
              icon: LucideIcons.messagesSquare,
              label: 'Chat en direct',
              description: 'Réponse immédiate, sans quitter l\'application',
              trailing: const AppBadge(
                label: 'Recommandé',
                tone: AppAccent.green,
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.router.push(
                  SupportChatRoute(
                    visitorName: visitorName,
                    visitorEmail: visitorEmail,
                  ),
                );
              },
            ),
          AppSheetAction(
            // Logo de marque : WhatsApp reste reconnaissable d'un coup d'œil.
            iconWidget: FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: t.muted),
            label: 'WhatsApp',
            description: _formatPhone(AppConfig.supportWhatsApp),
            onTap: () => _run(
              context,
              () => LauncherHelper.openWhatsApp(
                AppConfig.supportWhatsApp,
                message: _whatsAppGreeting(),
              ),
            ),
          ),
          AppSheetAction(
            icon: LucideIcons.phone,
            label: 'Appeler le support',
            description:
                '${_formatPhone(AppConfig.supportPhone)} · ${AppConfig.supportHours}',
            onTap: () => _run(
              context,
              () => LauncherHelper.makeCall('+${AppConfig.supportPhone}'),
            ),
          ),
          AppSheetAction(
            icon: LucideIcons.mail,
            label: 'Envoyer un e-mail',
            description: AppConfig.supportEmail,
            onTap: () => _run(
              context,
              () => LauncherHelper.openUrl(
                'mailto:${AppConfig.supportEmail}'
                '?subject=${Uri.encodeComponent('Demande d\'assistance Resi')}',
              ),
            ),
          ),
          AppSheetAction(
            icon: LucideIcons.globe,
            label: 'Site web',
            description: _formatWebsite(AppConfig.supportWebsite),
            onTap: () => _run(
              context,
              () => LauncherHelper.openUrl(AppConfig.supportWebsite),
            ),
          ),
        ],
      ),
    );
  }

  String _whatsAppGreeting() {
    final name = visitorName?.trim();
    if (name == null || name.isEmpty) {
      return 'Bonjour, j\'ai besoin d\'aide sur Resi.';
    }
    return 'Bonjour, je suis $name. J\'ai besoin d\'aide sur Resi.';
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    Navigator.of(context).pop();
    try {
      await action();
    } on LauncherException {
      // Sans `context` : la feuille est déjà refermée quand l'échec survient,
      // le toast se pose alors sur l'`Overlay` du routeur racine.
      AppToast.error('Aucune application disponible pour ce canal.');
    }
  }

  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith('225') || digits.length != 13) return '+$digits';

    final local = digits.substring(3);
    final pairs = <String>[
      for (var i = 0; i < local.length; i += 2) local.substring(i, i + 2),
    ];
    return '+225 ${pairs.join(' ')}';
  }

  static String _formatWebsite(String url) => url
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/$'), '');
}
