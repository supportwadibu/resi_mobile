// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i5;
import 'package:resi_africa/features/wallet/data/models/wallet_model.dart'
    as _i4;
import 'package:resi_africa/features/wallet/presentation/screens/wallet_screen.dart'
    as _i1;
import 'package:resi_africa/features/wallet/presentation/screens/wallet_transactions_screen.dart'
    as _i2;

/// generated route for
/// [_i1.WalletScreen]
class WalletRoute extends _i3.PageRouteInfo<void> {
  const WalletRoute({List<_i3.PageRouteInfo>? children})
    : super(WalletRoute.name, initialChildren: children);

  static const String name = 'WalletRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i1.WalletScreen();
    },
  );
}

/// generated route for
/// [_i2.WalletTransactionsScreen]
class WalletTransactionsRoute
    extends _i3.PageRouteInfo<WalletTransactionsRouteArgs> {
  WalletTransactionsRoute({
    required _i4.WalletModel wallet,
    _i5.Key? key,
    List<_i3.PageRouteInfo>? children,
  }) : super(
         WalletTransactionsRoute.name,
         args: WalletTransactionsRouteArgs(wallet: wallet, key: key),
         initialChildren: children,
       );

  static const String name = 'WalletTransactionsRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WalletTransactionsRouteArgs>();
      return _i2.WalletTransactionsScreen(wallet: args.wallet, key: args.key);
    },
  );
}

class WalletTransactionsRouteArgs {
  const WalletTransactionsRouteArgs({required this.wallet, this.key});

  final _i4.WalletModel wallet;

  final _i5.Key? key;

  @override
  String toString() {
    return 'WalletTransactionsRouteArgs{wallet: $wallet, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WalletTransactionsRouteArgs) return false;
    return wallet == other.wallet && key == other.key;
  }

  @override
  int get hashCode => wallet.hashCode ^ key.hashCode;
}
