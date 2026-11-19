import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/config/app_config.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/utils/launcher_helper.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

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
    final channels = [
      _Channel(
        icon: FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: t.foreground),
        label: 'support.whatsapp'.tr(),
        detail: _formatPhone(AppConfig.supportWhatsApp),
        onTap: () => _run(
          context,
          () => LauncherHelper.openWhatsApp(
            AppConfig.supportWhatsApp,
            message: _whatsAppGreeting(),
          ),
        ),
      ),
      _Channel(
        icon: Icon(LucideIcons.phone, size: 18, color: t.foreground),
        label: 'support.call'.tr(),
        detail: AppConfig.supportHours.isEmpty
            ? 'support.hours'.tr()
            : AppConfig.supportHours,
        onTap: () => _run(
          context,
          () => LauncherHelper.makeCall('+${AppConfig.supportPhone}'),
        ),
      ),
      _Channel(
        icon: Icon(LucideIcons.mail, size: 18, color: t.foreground),
        label: 'support.email'.tr(),
        detail: AppConfig.supportEmail,
        onTap: () => _run(
          context,
          () => LauncherHelper.openUrl(
            'mailto:${AppConfig.supportEmail}'
            '?subject=${Uri.encodeComponent('support.email_subject'.tr())}',
          ),
        ),
      ),
      _Channel(
        icon: Icon(LucideIcons.globe, size: 18, color: t.foreground),
        label: 'support.website'.tr(),
        detail: _formatWebsite(AppConfig.supportWebsite),
        onTap: () => _run(
          context,
          () => LauncherHelper.openUrl(AppConfig.supportWebsite),
        ),
      ),
    ];

    return AppSheet(
      title: 'support.need_help'.tr(),
      description: 'support.how_to_reach'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (AppConfig.isSupportChatEnabled) ...[
            // Le canal le plus rapide, en grande carte lavande : guider vers
            // lui sans masquer les autres.
            Material(
              color: t.lavender,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  context.router.push(
                    SupportChatRoute(
                      visitorName: visitorName,
                      visitorEmail: visitorEmail,
                    ),
                  );
                },
                child: HaloSurface(
                  radius: AppRadius.lg,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: t.onLavender.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.pill,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'support.recommended'.tr(),
                                    style: context.text.labelSmall!.copyWith(
                                      color: t.onLavender,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'support.live_chat'.tr(),
                                style: context.text.titleLarge!.copyWith(
                                  color: t.onLavender,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'support.live_chat_hint'.tr(),
                                style: context.text.bodySmall!.copyWith(
                                  color: t.onLavender.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.onOverlay,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: 44,
                            child: Icon(
                              LucideIcons.messagesSquare,
                              size: 18,
                              color: t.onLavender,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (var i = 0; i < channels.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: channels[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < channels.length
                      ? channels[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
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

/// Tuile d'un canal de contact : disque d'icône, nom, coordonnée.
class _Channel extends StatelessWidget {
  const _Channel({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.background,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 124,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surface,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Center(child: icon),
                      ),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.arrowUpRight, size: 16, color: t.muted),
                  ],
                ),
                const Spacer(),
                Text(label, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
