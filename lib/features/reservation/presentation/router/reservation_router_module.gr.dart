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
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart'
    as _i8;
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart'
    as _i7;
import 'package:resi_africa/features/reservation/presentation/screens/add_reservation.dart'
    as _i1;
import 'package:resi_africa/features/reservation/presentation/screens/details_reservation_screen.dart'
    as _i2;
import 'package:resi_africa/features/reservation/presentation/screens/reservation_screen.dart'
    as _i3;
import 'package:resi_africa/features/reservation/presentation/screens/stay_extension_screen.dart'
    as _i4;

/// generated route for
/// [_i1.AddReservationScreen]
class AddReservationRoute extends _i5.PageRouteInfo<AddReservationRouteArgs> {
  AddReservationRoute({
    _i6.Key? key,
    _i8.ReservationMode mode = _i8.ReservationMode.checkIn,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         AddReservationRoute.name,
         args: AddReservationRouteArgs(key: key, mode: mode),
         initialChildren: children,
       );

  static const String name = 'AddReservationRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddReservationRouteArgs>(
        orElse: () => const AddReservationRouteArgs(),
      );
      return _i1.AddReservationScreen(key: args.key, mode: args.mode);
    },
  );
}

class AddReservationRouteArgs {
  const AddReservationRouteArgs({
    this.key,
    this.mode = _i8.ReservationMode.checkIn,
  });

  final _i6.Key? key;

  final _i8.ReservationMode mode;

  @override
  String toString() {
    return 'AddReservationRouteArgs{key: $key, mode: $mode}';
  }
}

/// generated route for
/// [_i2.DetailsReservationScreen]
class DetailsReservationRoute
    extends _i5.PageRouteInfo<DetailsReservationRouteArgs> {
  DetailsReservationRoute({
    _i6.Key? key,
    required _i7.ReservationModel reservation,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         DetailsReservationRoute.name,
         args: DetailsReservationRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'DetailsReservationRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailsReservationRouteArgs>();
      return _i2.DetailsReservationScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class DetailsReservationRouteArgs {
  const DetailsReservationRouteArgs({this.key, required this.reservation});

  final _i6.Key? key;

  final _i7.ReservationModel reservation;

  @override
  String toString() {
    return 'DetailsReservationRouteArgs{key: $key, reservation: $reservation}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DetailsReservationRouteArgs) return false;
    return key == other.key && reservation == other.reservation;
  }

  @override
  int get hashCode => key.hashCode ^ reservation.hashCode;
}

/// generated route for
/// [_i3.ReservationScreen]
class ReservationRoute extends _i5.PageRouteInfo<void> {
  const ReservationRoute({List<_i5.PageRouteInfo>? children})
    : super(ReservationRoute.name, initialChildren: children);

  static const String name = 'ReservationRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.ReservationScreen();
    },
  );
}

/// generated route for
/// [_i4.StayExtensionScreen]
class StayExtensionRoute extends _i5.PageRouteInfo<StayExtensionRouteArgs> {
  StayExtensionRoute({
    _i6.Key? key,
    required _i7.ReservationModel reservation,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         StayExtensionRoute.name,
         args: StayExtensionRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'StayExtensionRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StayExtensionRouteArgs>();
      return _i4.StayExtensionScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class StayExtensionRouteArgs {
  const StayExtensionRouteArgs({this.key, required this.reservation});

  final _i6.Key? key;

  final _i7.ReservationModel reservation;

  @override
  String toString() {
    return 'StayExtensionRouteArgs{key: $key, reservation: $reservation}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StayExtensionRouteArgs) return false;
    return key == other.key && reservation == other.reservation;
  }

  @override
  int get hashCode => key.hashCode ^ reservation.hashCode;
}
