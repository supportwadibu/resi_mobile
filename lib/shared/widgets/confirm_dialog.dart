import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/error/failures.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_button.dart';

/// Demande confirmation avant une action, miroir de `ConfirmDialog` du
/// backoffice.
///
/// [onConfirm] est facultatif et asynchrone : pendant l'attente, les boutons
/// sont désactivés ; en cas de succès le dialogue se ferme sur `true` ; en
/// cas d'échec, le message s'affiche **dans** le dialogue, qui reste ouvert
/// pour réessayer. Sans [onConfirm], le dialogue rend simplement `true` ou
/// `false`.
///
/// `danger` : bouton rouge, et le focus initial va à « Annuler » — un appui
/// machinal ne doit pas détruire.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
  Future<void> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(
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

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
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
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
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
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null)
              Text(widget.message!, style: context.mutedText),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: t.dangerSurface,
                child: Text(
                  _error!,
                  style: context.text.bodyMedium!.copyWith(color: t.danger),
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          AppButton(
            label: widget.cancelLabel,
            variant: AppButtonVariant.secondary,
            onPressed: _pending ? null : () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: widget.confirmLabel,
            variant: widget.danger
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            isLoading: _pending,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
