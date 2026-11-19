import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mouvement de l'interface : quelques durées et courbes partagées, et les
/// gestes qui reviennent partout — presser, apparaître, compter.
///
/// Recopié à l'identique dans l'application propriétaire : les deux
/// applications bougent de la même façon, comme elles partagent leurs jetons.
///
/// Règle : le mouvement accompagne un geste ou une arrivée, il ne décore
/// pas. Rien ne boucle, rien ne retarde une action, et tout s'efface quand
/// le système demande de réduire les animations.
abstract final class AppMotion {
  /// Retour d'un toucher : immédiat, ou le doigt attend.
  static const fast = Duration(milliseconds: 120);

  /// Changement d'état d'un composant : sélection, apparition.
  static const base = Duration(milliseconds: 240);

  /// Arrivée d'un écran ou d'un bloc entier.
  static const slow = Duration(milliseconds: 420);

  /// Décélération franche : l'élément arrive vite et se pose.
  static const enter = Curves.easeOutCubic;

  /// Léger dépassement, pour ce qui se confirme (coche, succès).
  static const pop = Curves.easeOutBack;

  /// Décalage entre deux éléments d'une liste qui apparaît en cascade. Borné :
  /// au-delà de quelques lignes, l'attente se sentirait.
  static const stagger = Duration(milliseconds: 45);
  static const maxStaggered = 8;

  /// Le système demande moins de mouvement : tout se pose sans animer.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Se tasse légèrement sous le doigt, comme un vrai bouton.
///
/// Au poser du doigt et non au relâcher : le retour doit précéder l'action.
/// [haptic] ajoute un clic discret, réservé aux gestes qui engagent.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    this.haptic = false,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final bool haptic;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    if (down && widget.haptic) HapticFeedback.selectionClick();
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Apparaît en montant légèrement, une seule fois, à sa première image.
///
/// [index] décale l'apparition dans une liste, pour qu'elle se lise de haut en
/// bas plutôt que d'un bloc ; au-delà de `AppMotion.maxStaggered`, les
/// éléments n'attendent plus — ceux qui défilent ensuite n'ont pas à patienter.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.duration = AppMotion.slow,
    super.key,
  });

  final Widget child;
  final int index;

  /// Distance parcourue en montant, en pixels logiques.
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    final step = widget.index.clamp(0, AppMotion.maxStaggered);
    Future.delayed(AppMotion.stagger * step, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Chiffre clé qui défile jusqu'à sa valeur à sa première apparition, puis
/// d'une valeur à l'autre quand elle change.
///
/// Prend le texte déjà mis en forme (« 245 000 F », « 82 % ») : seul le
/// premier nombre défile, le reste — séparateurs, unité — est gardé tel quel.
/// Un texte sans nombre s'affiche simplement.
class CountUpText extends StatelessWidget {
  const CountUpText(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  static final _number = RegExp(r'\d[\d\s  .]*\d|\d');

  @override
  Widget build(BuildContext context) {
    final match = _number.firstMatch(text);
    if (match == null || AppMotion.reduced(context)) {
      return Text(text, style: style);
    }
    final raw = match.group(0)!;
    final target = int.tryParse(raw.replaceAll(RegExp(r'\D'), ''));
    if (target == null) return Text(text, style: style);

    // Séparateur des milliers tel que le formatage l'a écrit (espace fine,
    // insécable, point) : le nombre défilant garde la même allure.
    final separator = RegExp(r'[\s  .]').firstMatch(raw)?.group(0);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: target.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) {
        final shown = _group(value.round(), separator);
        return Text(
          text.replaceRange(match.start, match.end, shown),
          style: style,
        );
      },
    );
  }

  static String _group(int value, String? separator) {
    final digits = value.toString();
    if (separator == null) return digits;
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(separator);
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// Transition d'écran : fondu et légère montée, l'écran suivant se pose sur
/// le précédent. Plus doux que le glissement latéral, et identique sur les
/// deux plateformes.
class FadeRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => fadeRise(animation, child);

  static Widget fadeRise(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Arrive en grossissant avec un léger rebond, une seule fois : réservé à ce
/// qui confirme — la coche d'un paiement, la clé d'une arrivée. Utilisé
/// partout, il perdrait ce sens.
class PopIn extends StatefulWidget {
  const PopIn({required this.child, this.delay = Duration.zero, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.pop,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.scale(scale: 0.6 + 0.4 * _curve.value, child: child),
      ),
    );
  }
}
