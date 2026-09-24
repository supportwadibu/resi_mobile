import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

/// Nature du retour, qui fixe la couleur et l'icône.
enum AppToastType { success, error, warning, info }

/// Retour bref après une action : création, suppression, envoi, connexion.
///
/// Passe par l'`Overlay` et non par `ScaffoldMessenger` : le toast doit
/// survivre à la fermeture de l'écran qui le déclenche — une suppression
/// referme souvent sa page — là où une `SnackBar` disparaît avec son
/// `Scaffold`.
///
/// Toujours préférer les raccourcis [AppToast.success], [AppToast.error],
/// [AppToast.warning] et [AppToast.info] à un appel direct.
abstract final class AppToast {
  /// Une action a abouti : « Bien enregistré », « Client supprimé ».
  static void success(String message, {BuildContext? context}) =>
      _show(message, AppToastType.success, context);

  /// Une action a échoué. Y passer le `userMessage` d'un `AppFailure`, jamais
  /// son `debugMessage`.
  static void error(String message, {BuildContext? context}) =>
      _show(message, AppToastType.error, context);

  /// L'action a abouti partiellement, ou demande une attention.
  static void warning(String message, {BuildContext? context}) =>
      _show(message, AppToastType.warning, context);

  /// Information neutre, sans succès ni échec.
  static void info(String message, {BuildContext? context}) =>
      _show(message, AppToastType.info, context);

  /// Toast affiché en ce moment, refermé avant d'en poser un autre.
  ///
  /// Sans cela, deux actions rapprochées empileraient leurs bandeaux au même
  /// endroit de l'écran, illisibles l'un sur l'autre.
  static OverlayEntry? _current;

  /// [context] est facultatif : à défaut, l'`Overlay` du routeur racine est
  /// utilisé. C'est ce qui permet d'annoncer une suppression après un `await`
  /// sans conserver de `BuildContext` au travers de la coupure asynchrone.
  static void _show(String message, AppToastType type, BuildContext? context) {
    if (message.trim().isEmpty) return;

    final overlay = context != null
        ? Overlay.maybeOf(context, rootOverlay: true)
        : sl<AppRouter>().navigatorKey.currentState?.overlay;

    // Sans `Overlay` — un test de widget nu, par exemple — le toast est
    // abandonné plutôt que de faire échouer l'action qu'il annonçait.
    if (overlay == null) return;

    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _ToastView(message: message, type: type),
    );

    _current = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 3200), () {
      // Un autre toast a pu prendre la place entre-temps : ne refermer que
      // celui que cette minuterie a posé.
      if (_current == entry) _dismiss();
    });
  }

  static void _dismiss() {
    _current?.remove();
    _current = null;
  }
}

/// Bandeau, animé à l'entrée comme à la sortie.
class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color accent, Color background, IconData icon}) get _style {
    return switch (widget.type) {
      AppToastType.success => (
        accent: AppColors.success,
        background: AppColors.successBg,
        icon: Icons.check_circle_outline_rounded,
      ),
      AppToastType.error => (
        accent: AppColors.error,
        background: AppColors.errorBg,
        icon: Icons.error_outline_rounded,
      ),
      AppToastType.warning => (
        accent: AppColors.warning,
        background: AppColors.warningBg,
        icon: Icons.warning_amber_rounded,
      ),
      AppToastType.info => (
        accent: AppColors.info,
        background: AppColors.infoBg,
        icon: Icons.info_outline_rounded,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final media = MediaQuery.of(context);

    return Positioned(
      // Sous l'encoche, jamais dessous : `media.padding.top` suit la barre
      // d'état de chaque appareil.
      top: media.padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: style.accent.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, color: style.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      // Un message serveur peut être long : il est tronqué
                      // plutôt que d'étirer le bandeau sur tout l'écran.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
