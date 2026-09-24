// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;
import 'package:resi_africa/features/clients/business_logic/client_detail_cubit.dart'
    as _i8;
import 'package:resi_africa/features/clients/data/models/client_model.dart'
    as _i7;
import 'package:resi_africa/features/clients/presentation/screens/add_client_screen.dart'
    as _i1;
import 'package:resi_africa/features/clients/presentation/screens/client_detail_screen.dart'
    as _i2;
import 'package:resi_africa/features/clients/presentation/screens/clients_screen.dart'
    as _i3;
import 'package:resi_africa/features/clients/presentation/screens/edit_client_screen.dart'
    as _i4;

/// generated route for
/// [_i1.AddClientScreen]
class AddClientRoute extends _i5.PageRouteInfo<void> {
  const AddClientRoute({List<_i5.PageRouteInfo>? children})
    : super(AddClientRoute.name, initialChildren: children);

  static const String name = 'AddClientRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddClientScreen();
    },
  );
}

/// generated route for
/// [_i2.ClientDetailScreen]
class ClientDetailRoute extends _i5.PageRouteInfo<ClientDetailRouteArgs> {
  ClientDetailRoute({
    _i6.Key? key,
    required _i7.ClientModel client,
    _i6.VoidCallback? onArchiveToggle,
    List<_i5.PageRouteInfo>? children,
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

  static _i5.PageInfo page = _i5.PageInfo(
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

  final _i6.Key? key;

  final _i7.ClientModel client;

  final _i6.VoidCallback? onArchiveToggle;

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
class ClientsRoute extends _i5.PageRouteInfo<void> {
  const ClientsRoute({List<_i5.PageRouteInfo>? children})
    : super(ClientsRoute.name, initialChildren: children);

  static const String name = 'ClientsRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.ClientsScreen();
    },
  );
}

/// generated route for
/// [_i4.EditClientScreen]
class EditClientRoute extends _i5.PageRouteInfo<EditClientRouteArgs> {
  EditClientRoute({
    _i6.Key? key,
    required _i7.ClientModel client,
    required _i8.ClientDetailCubit cubit,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         EditClientRoute.name,
         args: EditClientRouteArgs(key: key, client: client, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'EditClientRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditClientRouteArgs>();
      return _i4.EditClientScreen(
        key: args.key,
        client: args.client,
        cubit: args.cubit,
      );
    },
  );
}

class EditClientRouteArgs {
  const EditClientRouteArgs({
    this.key,
    required this.client,
    required this.cubit,
  });

  final _i6.Key? key;

  final _i7.ClientModel client;

  final _i8.ClientDetailCubit cubit;

  @override
  String toString() {
    return 'EditClientRouteArgs{key: $key, client: $client, cubit: $cubit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditClientRouteArgs) return false;
    return key == other.key && client == other.client && cubit == other.cubit;
  }

  @override
  int get hashCode => key.hashCode ^ client.hashCode ^ cubit.hashCode;
}
