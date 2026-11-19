import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/error/failures.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// Demande confirmation avant une action, dans une feuille du bas : titre et
/// explication, puis l'action en pleine largeur et « Annuler » dessous —
/// déconnexion, suppression, annulation passent toutes par ici.
///
/// [onConfirm] est facultatif et asynchrone : pendant l'attente, les boutons
/// sont désactivés et la feuille ne se ferme pas ; en cas de succès elle se
/// ferme sur `true` ; en cas d'échec, le message s'affiche **dans** la
/// feuille, qui reste ouverte pour réessayer. Sans [onConfirm], elle rend
/// simplement `true` ou `false`.
///
/// `danger` : pastille et bouton rouges — un geste qui détruit se reconnaît
/// avant d'être fait.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
  Future<void> Function()? onConfirm,
}) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (_) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? 'common.confirm'.tr(),
      cancelLabel: cancelLabel ?? 'common.cancel'.tr(),
      danger: danger,
      onConfirm: onConfirm,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
    required this.onConfirm,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final Future<void> Function()? onConfirm;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _pending = false;
  String? _error;

  Future<void> _confirm() async {
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = failure.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = 'common.action_failed'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopScope(
      canPop: !_pending,
      child: AppSheet(
        title: widget.title,
        description: widget.message,
        showClose: false,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: widget.confirmLabel,
              variant: widget.danger
                  ? AppButtonVariant.danger
                  : AppButtonVariant.primary,
              expand: true,
              isLoading: _pending,
              onPressed: _pending ? null : _confirm,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: widget.cancelLabel,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: _pending
                  ? null
                  : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.danger ? t.dangerSurface : t.accentVioletSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.danger
                    ? LucideIcons.triangleAlert
                    : LucideIcons.circleHelp,
                size: 24,
                color: widget.danger ? t.danger : t.accentViolet,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.dangerSurface,
                  borderRadius: AppRadius.md,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _error!,
                    style: context.text.bodyMedium!.copyWith(color: t.danger),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
