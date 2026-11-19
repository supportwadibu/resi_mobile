import 'package:flutter/material.dart';

import '../shared/motion/motion.dart';

/// Transition commune aux modules de routes : fondu et légère montée, la
/// même que celle du thème (`FadeRisePageTransitionsBuilder`) — un écran
/// ouvert depuis un module ne doit pas arriver autrement que les autres.
RouteTransitionsBuilder get customTransitionBuilder =>
    (context, animation, secondaryAnimation, child) =>
        AppMotion.reduced(context)
        ? child
        : FadeRisePageTransitionsBuilder.fadeRise(animation, child);
