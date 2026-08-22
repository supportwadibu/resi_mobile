// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/material.dart' as _i5;
import 'package:resi_africa/features/clients/data/models/client_model.dart'
    as _i6;
import 'package:resi_africa/features/clients/presentation/screens/add_client_screen.dart'
    as _i1;
import 'package:resi_africa/features/clients/presentation/screens/client_detail_screen.dart'
    as _i2;
import 'package:resi_africa/features/clients/presentation/screens/clients_screen.dart'
    as _i3;

/// generated route for
/// [_i1.AddClientScreen]
class AddClientRoute extends _i4.PageRouteInfo<void> {
  const AddClientRoute({List<_i4.PageRouteInfo>? children})
    : super(AddClientRoute.name, initialChildren: children);

  static const String name = 'AddClientRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddClientScreen();
    },
  );
}

/// generated route for
/// [_i2.ClientDetailScreen]
class ClientDetailRoute extends _i4.PageRouteInfo<ClientDetailRouteArgs> {
  ClientDetailRoute({
    _i5.Key? key,
    required _i6.ClientModel client,
    _i5.VoidCallback? onArchiveToggle,
    List<_i4.PageRouteInfo>? children,
  }) : super(
         ClientDetailRoute.name,
         args: ClientDetailRouteArgs(
           key: key,
           client: client,
           onArchiveToggle: onArchiveToggle,
         ),
         initialChildren: children,
       );

  static const String name = 'ClientDetailRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ClientDetailRouteArgs>();
      return _i2.ClientDetailScreen(
        key: args.key,
        client: args.client,
        onArchiveToggle: args.onArchiveToggle,
      );
    },
  );
}

class ClientDetailRouteArgs {
  const ClientDetailRouteArgs({
    this.key,
    required this.client,
    this.onArchiveToggle,
  });

  final _i5.Key? key;

  final _i6.ClientModel client;

  final _i5.VoidCallback? onArchiveToggle;

  @override
  String toString() {
    return 'ClientDetailRouteArgs{key: $key, client: $client, onArchiveToggle: $onArchiveToggle}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClientDetailRouteArgs) return false;
    return key == other.key &&
        client == other.client &&
        onArchiveToggle == other.onArchiveToggle;
  }

  @override
  int get hashCode => key.hashCode ^ client.hashCode ^ onArchiveToggle.hashCode;
}

/// generated route for
/// [_i3.ClientsScreen]
class ClientsRoute extends _i4.PageRouteInfo<void> {
  const ClientsRoute({List<_i4.PageRouteInfo>? children})
    : super(ClientsRoute.name, initialChildren: children);

  static const String name = 'ClientsRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i3.ClientsScreen();
    },
  );
}
