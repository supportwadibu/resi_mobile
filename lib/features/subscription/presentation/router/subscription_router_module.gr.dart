// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/material.dart' as _i6;
import 'package:resi_africa/features/subscription/data/models/plan_access.dart'
    as _i5;
import 'package:resi_africa/features/subscription/presentation/screens/subscription_plans_screen.dart'
    as _i1;
import 'package:resi_africa/features/subscription/presentation/screens/trial_ended_screen.dart'
    as _i2;
import 'package:resi_africa/features/subscription/presentation/screens/trial_plan_choice_screen.dart'
    as _i3;

/// generated route for
/// [_i1.SubscriptionPlansScreen]
class SubscriptionPlansRoute
    extends _i4.PageRouteInfo<SubscriptionPlansRouteArgs> {
  SubscriptionPlansRoute({
    bool blocking = false,
    _i5.PlanAccess? focus,
    _i6.Key? key,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         SubscriptionPlansRoute.name,
         args: SubscriptionPlansRouteArgs(
           blocking: blocking,
           focus: focus,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'SubscriptionPlansRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubscriptionPlansRouteArgs>(
        orElse: () => const SubscriptionPlansRouteArgs(),
      );
      return _i1.SubscriptionPlansScreen(
        blocking: args.blocking,
        focus: args.focus,
        key: args.key,
      );
    },
  );
}

class SubscriptionPlansRouteArgs {
  const SubscriptionPlansRouteArgs({
    this.blocking = false,
    this.focus,
    this.key,
  });

  final bool blocking;

  final _i5.PlanAccess? focus;

  final _i6.Key? key;

  @override
  String toString() {
    return 'SubscriptionPlansRouteArgs{blocking: $blocking, focus: $focus, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubscriptionPlansRouteArgs) return false;
    return blocking == other.blocking &&
        focus == other.focus &&
        key == other.key;
  }

  @override
  int get hashCode => blocking.hashCode ^ focus.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i2.TrialEndedScreen]
class TrialEndedRoute extends _i4.PageRouteInfo<TrialEndedRouteArgs> {
  TrialEndedRoute({
    required _i5.PlanAccess tier,
    _i6.Key? key,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         TrialEndedRoute.name,
         args: TrialEndedRouteArgs(tier: tier, key: key),
         initialChildren: children,
       );

  static const String name = 'TrialEndedRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TrialEndedRouteArgs>();
      return _i2.TrialEndedScreen(tier: args.tier, key: args.key);
    },
  );
}

class TrialEndedRouteArgs {
  const TrialEndedRouteArgs({required this.tier, this.key});

  final _i5.PlanAccess tier;

  final _i6.Key? key;

  @override
  String toString() {
    return 'TrialEndedRouteArgs{tier: $tier, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TrialEndedRouteArgs) return false;
    return tier == other.tier && key == other.key;
  }

  @override
  int get hashCode => tier.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i3.TrialPlanChoiceScreen]
class TrialPlanChoiceRoute extends _i4.PageRouteInfo<void> {
  const TrialPlanChoiceRoute({List<_i4.PageRouteInfo>? children})
    : super(TrialPlanChoiceRoute.name, initialChildren: children);

  static const String name = 'TrialPlanChoiceRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i3.TrialPlanChoiceScreen();
    },
  );
}
