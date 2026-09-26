// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i3;
import 'package:resi_africa/features/subscription/presentation/screens/subscription_plans_screen.dart'
    as _i1;

/// generated route for
/// [_i1.SubscriptionPlansScreen]
class SubscriptionPlansRoute
    extends _i2.PageRouteInfo<SubscriptionPlansRouteArgs> {
  SubscriptionPlansRoute({
    bool blocking = false,
    _i3.Key? key,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         SubscriptionPlansRoute.name,
         args: SubscriptionPlansRouteArgs(blocking: blocking, key: key),
         initialChildren: children,
       );

  static const String name = 'SubscriptionPlansRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubscriptionPlansRouteArgs>(
        orElse: () => const SubscriptionPlansRouteArgs(),
      );
      return _i1.SubscriptionPlansScreen(
        blocking: args.blocking,
        key: args.key,
      );
    },
  );
}

class SubscriptionPlansRouteArgs {
  const SubscriptionPlansRouteArgs({this.blocking = false, this.key});

  final bool blocking;

  final _i3.Key? key;

  @override
  String toString() {
    return 'SubscriptionPlansRouteArgs{blocking: $blocking, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubscriptionPlansRouteArgs) return false;
    return blocking == other.blocking && key == other.key;
  }

  @override
  int get hashCode => blocking.hashCode ^ key.hashCode;
}
