import 'package:easy_localization/easy_localization.dart';
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
      title: 'support.need_help'.tr(),
      description: 'support.how_to_reach'.tr(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (AppConfig.isSupportChatEnabled)
            // Le canal le plus rapide, en tête et marqué : guider vers lui
            // sans masquer les autres.
            AppSheetAction(
              icon: LucideIcons.messagesSquare,
              label: 'support.live_chat'.tr(),
              description: 'support.live_chat_hint'.tr(),
              trailing: AppBadge(
                label: 'support.recommended'.tr(),
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
            label: 'support.whatsapp'.tr(),
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
            label: 'support.call'.tr(),
            description:
                '${_formatPhone(AppConfig.supportPhone)} · '
                '${AppConfig.supportHours.isEmpty ? 'support.hours'.tr() : AppConfig.supportHours}',
            onTap: () => _run(
              context,
              () => LauncherHelper.makeCall('+${AppConfig.supportPhone}'),
            ),
          ),
          AppSheetAction(
            icon: LucideIcons.mail,
            label: 'support.email'.tr(),
            description: AppConfig.supportEmail,
            onTap: () => _run(
              context,
              () => LauncherHelper.openUrl(
                'mailto:${AppConfig.supportEmail}'
                '?subject=${Uri.encodeComponent('support.email_subject'.tr())}',
              ),
            ),
          ),
          AppSheetAction(
            icon: LucideIcons.globe,
            label: 'support.website'.tr(),
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
      return 'support.greeting'.tr();
    }
    return 'support.greeting_named'.tr(args: [name]);
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
      AppToast.error('support.no_app'.tr());
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
