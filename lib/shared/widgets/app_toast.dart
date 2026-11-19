import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/di/service_locator.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'frosted_surface.dart';

/// Nature du retour, qui fixe la couleur et l'icône.
enum AppToastType { success, error, warning, info }

/// Retour bref après une action : création, suppression, envoi, connexion —
/// et son échec. **Toute issue d'une action passe par ici**, jamais par un
/// encart dans l'écran ni par une `SnackBar`. Un encart (`AppCallout`) reste
/// réservé à un état qui dure : hors ligne, synchronisation, statut d'un
/// forfait.
///
/// Passe par l'`Overlay` et non par `ScaffoldMessenger` : le toast doit
/// survivre à la fermeture de l'écran qui le déclenche — une suppression
/// referme souvent sa page — là où une `SnackBar` disparaît avec son
/// `Scaffold`. L'`Overlay` racine le pose aussi au-dessus d'une feuille du
/// bas ouverte.
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
  static GlobalKey<_ToastViewState>? _currentKey;

  /// Durée d'affichage. Une erreur se lit plus longuement : c'est elle qui
  /// dit quoi corriger.
  static Duration _durationOf(AppToastType type) => switch (type) {
    AppToastType.error => const Duration(milliseconds: 4800),
    AppToastType.warning => const Duration(milliseconds: 4200),
    _ => const Duration(milliseconds: 3200),
  };

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

    // Le précédent part sans animation : le nouveau prend aussitôt sa place.
    _remove();

    final key = GlobalKey<_ToastViewState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        key: key,
        message: message,
        type: type,
        onDismiss: () => _dismiss(entry),
      ),
    );

    _current = entry;
    _currentKey = key;
    overlay.insert(entry);

    Future.delayed(_durationOf(type), () => _dismiss(entry));
  }

  /// Referme [entry] en jouant sa sortie, s'il est toujours affiché : un
  /// autre toast a pu prendre sa place entre-temps.
  static Future<void> _dismiss(OverlayEntry entry) async {
    if (_current != entry) return;
    await _currentKey?.currentState?.hide();
    if (_current == entry) _remove();
  }

  static void _remove() {
    _current?.remove();
    _current = null;
    _currentKey = null;
  }
}

/// Carte de verre flottante sous la barre d'état, animée à l'entrée comme à
/// la sortie. Un toucher la referme, un glissement vers le haut aussi.
class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.type,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  /// Joue la sortie ; rendu une fois la carte invisible.
  Future<void> hide() async {
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Le ton ne colore que le disque de l'icône : la carte reste de verre,
  /// comme tout ce qui flotte, et le message garde la couleur du texte.
  ({Color accent, Color soft, IconData icon}) _style(ResiTokens t) {
    return switch (widget.type) {
      AppToastType.success => (
        accent: t.accentGreen,
        soft: t.accentGreenSoft,
        icon: LucideIcons.check,
      ),
      AppToastType.error => (
        accent: t.danger,
        soft: t.dangerSurface,
        icon: LucideIcons.x,
      ),
      AppToastType.warning => (
        accent: t.accentAmber,
        soft: t.accentAmberSoft,
        icon: LucideIcons.triangleAlert,
      ),
      AppToastType.info => (
        accent: t.accentViolet,
        soft: t.accentVioletSoft,
        icon: LucideIcons.info,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = _style(t);
    final media = MediaQuery.of(context);

    return Positioned(
      // Sous l'encoche, jamais dessous : `media.padding.top` suit la barre
      // d'état de chaque appareil.
      top: media.padding.top + 10,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Semantics(
            liveRegion: true,
            container: true,
            child: GestureDetector(
              onTap: widget.onDismiss,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -120) widget.onDismiss();
              },
              child: Material(
                type: MaterialType.transparency,
                child: DecoratedBox(
                  // Seul relief permis : ce qui flotte au-dessus de tout
                  // l'écran doit s'en détacher, même sur une photo claire.
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lg,
                    boxShadow: [
                      BoxShadow(
                        color: t.foreground.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FrostedSurface(
                    borderRadius: AppRadius.lg,
                    opacity: 0.88,
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: style.soft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            style.icon,
                            color: style.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              widget.message,
                              // Un message serveur peut être long : il est
                              // tronqué plutôt que d'étirer la carte sur tout
                              // l'écran.
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: t.foreground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Annonce en toast un message porté par l'état d'un écran — l'échec d'un
/// envoi, typiquement — dès qu'il paraît ou change. Ne dessine rien.
///
/// Se pose là où se tenait l'encart d'erreur : `if (state case
/// Failure(:final message)) AppToastOnMessage(message)`. Un nouvel échec
/// après une nouvelle tentative se réannonce, l'état intermédiaire « en cours »
/// ayant retiré le widget.
class AppToastOnMessage extends StatefulWidget {
  const AppToastOnMessage(
    this.message, {
    this.type = AppToastType.error,
    super.key,
  });

  final String? message;
  final AppToastType type;

  @override
  State<AppToastOnMessage> createState() => _AppToastOnMessageState();
}

class _AppToastOnMessageState extends State<AppToastOnMessage> {
  @override
  void initState() {
    super.initState();
    _announce();
  }

  @override
  void didUpdateWidget(AppToastOnMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message) _announce();
  }

  /// Après l'image en cours : un toast ne s'insère pas dans l'`Overlay`
  /// pendant que l'arbre se construit.
  void _announce() {
    final message = widget.message;
    if (message == null || message.trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToast._show(message, widget.type, context);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
