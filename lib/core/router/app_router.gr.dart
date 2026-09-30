// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i34;
import 'package:flutter/material.dart' as _i35;
import 'package:resi_africa/features/auth/presentation/screens/auth_screen.dart'
    as _i8;
import 'package:resi_africa/features/auth/presentation/screens/login_screen.dart'
    as _i19;
import 'package:resi_africa/features/auth/presentation/screens/property_manager_profile_screen.dart'
    as _i22;
import 'package:resi_africa/features/auth/presentation/screens/register_screen.dart'
    as _i24;
import 'package:resi_africa/features/auth/presentation/screens/trial_welcome_screen.dart'
    as _i33;
import 'package:resi_africa/features/clients/business_logic/client_detail_cubit.dart'
    as _i41;
import 'package:resi_africa/features/clients/data/models/client_model.dart'
    as _i39;
import 'package:resi_africa/features/clients/presentation/screens/add_client_screen.dart'
    as _i1;
import 'package:resi_africa/features/clients/presentation/screens/client_detail_screen.dart'
    as _i9;
import 'package:resi_africa/features/clients/presentation/screens/clients_screen.dart'
    as _i10;
import 'package:resi_africa/features/clients/presentation/screens/edit_client_screen.dart'
    as _i12;
import 'package:resi_africa/features/expense/data/models/expense_model.dart'
    as _i36;
import 'package:resi_africa/features/expense/presentation/screens/add_expense_screen.dart'
    as _i2;
import 'package:resi_africa/features/expense/presentation/screens/expense_screen.dart'
    as _i14;
import 'package:resi_africa/features/gerant/presentation/screens/add_gerant_screen.dart'
    as _i3;
import 'package:resi_africa/features/gerant/presentation/screens/gerant_list_screen.dart'
    as _i16;
import 'package:resi_africa/features/gerant/presentation/screens/gerant_scope_screen.dart'
    as _i17;
import 'package:resi_africa/features/home/presentation/screens/all_reviews_screen.dart'
    as _i7;
import 'package:resi_africa/features/home/presentation/screens/home_screen.dart'
    as _i18;
import 'package:resi_africa/features/home/presentation/widgets/tabs/profile_tab.dart'
    as _i20;
import 'package:resi_africa/features/property/data/models/property_model.dart'
    as _i37;
import 'package:resi_africa/features/property/presentation/screens/add_property_screen.dart'
    as _i4;
import 'package:resi_africa/features/property/presentation/screens/property_detail_screen.dart'
    as _i21;
import 'package:resi_africa/features/property/presentation/screens/property_screen.dart'
    as _i23;
import 'package:resi_africa/features/property/presentation/screens/success_screen.dart'
    as _i31;
import 'package:resi_africa/features/rapport/presentation/screens/rapport_screen.dart'
    as _i25;
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart'
    as _i38;
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart'
    as _i40;
import 'package:resi_africa/features/reservation/presentation/screens/add_reservation.dart'
    as _i5;
import 'package:resi_africa/features/reservation/presentation/screens/details_reservation_screen.dart'
    as _i11;
import 'package:resi_africa/features/reservation/presentation/screens/edit_reservation_screen.dart'
    as _i13;
import 'package:resi_africa/features/reservation/presentation/screens/reservation_screen.dart'
    as _i26;
import 'package:resi_africa/features/reservation/presentation/screens/stay_extension_screen.dart'
    as _i29;
import 'package:resi_africa/features/residence/presentation/screens/add_residence_screen.dart'
    as _i6;
import 'package:resi_africa/features/residence/presentation/screens/residence_detail_screen.dart'
    as _i27;
import 'package:resi_africa/features/residence/presentation/screens/residence_screen.dart'
    as _i28;
import 'package:resi_africa/features/stats/presentation/screens/finance_screen.dart'
    as _i15;
import 'package:resi_africa/features/subscription/presentation/screens/subscription_plans_screen.dart'
    as _i30;
import 'package:resi_africa/features/support/presentation/screens/support_chat_screen.dart'
    as _i32;

/// generated route for
/// [_i1.AddClientScreen]
class AddClientRoute extends _i34.PageRouteInfo<void> {
  const AddClientRoute({List<_i34.PageRouteInfo>? children})
    : super(AddClientRoute.name, initialChildren: children);

  static const String name = 'AddClientRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddClientScreen();
    },
  );
}

/// generated route for
/// [_i2.AddExpenseScreen]
class AddExpenseRoute extends _i34.PageRouteInfo<AddExpenseRouteArgs> {
  AddExpenseRoute({
    _i35.Key? key,
    _i36.ExpenseModel? expense,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         AddExpenseRoute.name,
         args: AddExpenseRouteArgs(key: key, expense: expense),
         initialChildren: children,
       );

  static const String name = 'AddExpenseRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddExpenseRouteArgs>(
        orElse: () => const AddExpenseRouteArgs(),
      );
      return _i2.AddExpenseScreen(key: args.key, expense: args.expense);
    },
  );
}

class AddExpenseRouteArgs {
  const AddExpenseRouteArgs({this.key, this.expense});

  final _i35.Key? key;

  final _i36.ExpenseModel? expense;

  @override
  String toString() {
    return 'AddExpenseRouteArgs{key: $key, expense: $expense}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddExpenseRouteArgs) return false;
    return key == other.key && expense == other.expense;
  }

  @override
  int get hashCode => key.hashCode ^ expense.hashCode;
}

/// generated route for
/// [_i3.AddGerantScreen]
class AddGerantRoute extends _i34.PageRouteInfo<void> {
  const AddGerantRoute({List<_i34.PageRouteInfo>? children})
    : super(AddGerantRoute.name, initialChildren: children);

  static const String name = 'AddGerantRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddGerantScreen();
    },
  );
}

/// generated route for
/// [_i4.AddPropertyScreen]
class AddPropertyRoute extends _i34.PageRouteInfo<AddPropertyRouteArgs> {
  AddPropertyRoute({
    _i35.Key? key,
    _i37.PropertyModel? property,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         AddPropertyRoute.name,
         args: AddPropertyRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'AddPropertyRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddPropertyRouteArgs>(
        orElse: () => const AddPropertyRouteArgs(),
      );
      return _i4.AddPropertyScreen(key: args.key, property: args.property);
    },
  );
}

class AddPropertyRouteArgs {
  const AddPropertyRouteArgs({this.key, this.property});

  final _i35.Key? key;

  final _i37.PropertyModel? property;

  @override
  String toString() {
    return 'AddPropertyRouteArgs{key: $key, property: $property}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddPropertyRouteArgs) return false;
    return key == other.key && property == other.property;
  }

  @override
  int get hashCode => key.hashCode ^ property.hashCode;
}

/// generated route for
/// [_i5.AddReservationScreen]
class AddReservationRoute extends _i34.PageRouteInfo<AddReservationRouteArgs> {
  AddReservationRoute({
    _i38.ReservationMode mode = _i38.ReservationMode.checkIn,
    _i35.Key? key,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         AddReservationRoute.name,
         args: AddReservationRouteArgs(mode: mode, key: key),
         initialChildren: children,
       );

  static const String name = 'AddReservationRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddReservationRouteArgs>(
        orElse: () => const AddReservationRouteArgs(),
      );
      return _i5.AddReservationScreen(mode: args.mode, key: args.key);
    },
  );
}

class AddReservationRouteArgs {
  const AddReservationRouteArgs({
    this.mode = _i38.ReservationMode.checkIn,
    this.key,
  });

  final _i38.ReservationMode mode;

  final _i35.Key? key;

  @override
  String toString() {
    return 'AddReservationRouteArgs{mode: $mode, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddReservationRouteArgs) return false;
    return mode == other.mode && key == other.key;
  }

  @override
  int get hashCode => mode.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i6.AddResidenceScreen]
class AddResidenceRoute extends _i34.PageRouteInfo<AddResidenceRouteArgs> {
  AddResidenceRoute({
    _i35.Key? key,
    String? residenceId,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         AddResidenceRoute.name,
         args: AddResidenceRouteArgs(key: key, residenceId: residenceId),
         rawQueryParams: {'id': residenceId},
         initialChildren: children,
       );

  static const String name = 'AddResidenceRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AddResidenceRouteArgs>(
        orElse: () =>
            AddResidenceRouteArgs(residenceId: queryParams.optString('id')),
      );
      return _i6.AddResidenceScreen(
        key: args.key,
        residenceId: args.residenceId,
      );
    },
  );
}

class AddResidenceRouteArgs {
  const AddResidenceRouteArgs({this.key, this.residenceId});

  final _i35.Key? key;

  final String? residenceId;

  @override
  String toString() {
    return 'AddResidenceRouteArgs{key: $key, residenceId: $residenceId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddResidenceRouteArgs) return false;
    return key == other.key && residenceId == other.residenceId;
  }

  @override
  int get hashCode => key.hashCode ^ residenceId.hashCode;
}

/// generated route for
/// [_i7.AllReviewsScreen]
class AllReviewsRoute extends _i34.PageRouteInfo<void> {
  const AllReviewsRoute({List<_i34.PageRouteInfo>? children})
    : super(AllReviewsRoute.name, initialChildren: children);

  static const String name = 'AllReviewsRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i7.AllReviewsScreen();
    },
  );
}

/// generated route for
/// [_i8.AuthScreen]
class AuthRoute extends _i34.PageRouteInfo<void> {
  const AuthRoute({List<_i34.PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i8.AuthScreen();
    },
  );
}

/// generated route for
/// [_i9.ClientDetailScreen]
class ClientDetailRoute extends _i34.PageRouteInfo<ClientDetailRouteArgs> {
  ClientDetailRoute({
    _i35.Key? key,
    required _i39.ClientModel client,
    _i35.VoidCallback? onArchiveToggle,
    List<_i34.PageRouteInfo>? children,
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

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ClientDetailRouteArgs>();
      return _i9.ClientDetailScreen(
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

  final _i35.Key? key;

  final _i39.ClientModel client;

  final _i35.VoidCallback? onArchiveToggle;

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
/// [_i10.ClientsScreen]
class ClientsRoute extends _i34.PageRouteInfo<void> {
  const ClientsRoute({List<_i34.PageRouteInfo>? children})
    : super(ClientsRoute.name, initialChildren: children);

  static const String name = 'ClientsRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i10.ClientsScreen();
    },
  );
}

/// generated route for
/// [_i11.DetailsReservationScreen]
class DetailsReservationRoute
    extends _i34.PageRouteInfo<DetailsReservationRouteArgs> {
  DetailsReservationRoute({
    _i35.Key? key,
    required _i40.ReservationModel reservation,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         DetailsReservationRoute.name,
         args: DetailsReservationRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'DetailsReservationRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailsReservationRouteArgs>();
      return _i11.DetailsReservationScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class DetailsReservationRouteArgs {
  const DetailsReservationRouteArgs({this.key, required this.reservation});

  final _i35.Key? key;

  final _i40.ReservationModel reservation;

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
/// [_i12.EditClientScreen]
class EditClientRoute extends _i34.PageRouteInfo<EditClientRouteArgs> {
  EditClientRoute({
    _i35.Key? key,
    required _i39.ClientModel client,
    required _i41.ClientDetailCubit cubit,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         EditClientRoute.name,
         args: EditClientRouteArgs(key: key, client: client, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'EditClientRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditClientRouteArgs>();
      return _i12.EditClientScreen(
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

  final _i35.Key? key;

  final _i39.ClientModel client;

  final _i41.ClientDetailCubit cubit;

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

/// generated route for
/// [_i13.EditReservationScreen]
class EditReservationRoute
    extends _i34.PageRouteInfo<EditReservationRouteArgs> {
  EditReservationRoute({
    required _i40.ReservationModel reservation,
    _i35.Key? key,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         EditReservationRoute.name,
         args: EditReservationRouteArgs(reservation: reservation, key: key),
         initialChildren: children,
       );

  static const String name = 'EditReservationRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditReservationRouteArgs>();
      return _i13.EditReservationScreen(
        reservation: args.reservation,
        key: args.key,
      );
    },
  );
}

class EditReservationRouteArgs {
  const EditReservationRouteArgs({required this.reservation, this.key});

  final _i40.ReservationModel reservation;

  final _i35.Key? key;

  @override
  String toString() {
    return 'EditReservationRouteArgs{reservation: $reservation, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditReservationRouteArgs) return false;
    return reservation == other.reservation && key == other.key;
  }

  @override
  int get hashCode => reservation.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i14.ExpenseScreen]
class ExpenseRoute extends _i34.PageRouteInfo<void> {
  const ExpenseRoute({List<_i34.PageRouteInfo>? children})
    : super(ExpenseRoute.name, initialChildren: children);

  static const String name = 'ExpenseRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i14.ExpenseScreen();
    },
  );
}

/// generated route for
/// [_i15.FinanceScreen]
class FinanceRoute extends _i34.PageRouteInfo<void> {
  const FinanceRoute({List<_i34.PageRouteInfo>? children})
    : super(FinanceRoute.name, initialChildren: children);

  static const String name = 'FinanceRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i15.FinanceScreen();
    },
  );
}

/// generated route for
/// [_i16.GerantListScreen]
class GerantListRoute extends _i34.PageRouteInfo<void> {
  const GerantListRoute({List<_i34.PageRouteInfo>? children})
    : super(GerantListRoute.name, initialChildren: children);

  static const String name = 'GerantListRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i16.GerantListScreen();
    },
  );
}

/// generated route for
/// [_i17.GerantScopeScreen]
class GerantScopeRoute extends _i34.PageRouteInfo<GerantScopeRouteArgs> {
  GerantScopeRoute({
    _i35.Key? key,
    required String gerantId,
    String? gerantName,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         GerantScopeRoute.name,
         args: GerantScopeRouteArgs(
           key: key,
           gerantId: gerantId,
           gerantName: gerantName,
         ),
         initialChildren: children,
       );

  static const String name = 'GerantScopeRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<GerantScopeRouteArgs>();
      return _i17.GerantScopeScreen(
        key: args.key,
        gerantId: args.gerantId,
        gerantName: args.gerantName,
      );
    },
  );
}

class GerantScopeRouteArgs {
  const GerantScopeRouteArgs({
    this.key,
    required this.gerantId,
    this.gerantName,
  });

  final _i35.Key? key;

  final String gerantId;

  final String? gerantName;

  @override
  String toString() {
    return 'GerantScopeRouteArgs{key: $key, gerantId: $gerantId, gerantName: $gerantName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GerantScopeRouteArgs) return false;
    return key == other.key &&
        gerantId == other.gerantId &&
        gerantName == other.gerantName;
  }

  @override
  int get hashCode => key.hashCode ^ gerantId.hashCode ^ gerantName.hashCode;
}

/// generated route for
/// [_i18.HomeScreen]
class HomeRoute extends _i34.PageRouteInfo<void> {
  const HomeRoute({List<_i34.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i18.HomeScreen();
    },
  );
}

/// generated route for
/// [_i19.LoginScreen]
class LoginRoute extends _i34.PageRouteInfo<void> {
  const LoginRoute({List<_i34.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i19.LoginScreen();
    },
  );
}

/// generated route for
/// [_i20.ProfileScreen]
class ProfileRoute extends _i34.PageRouteInfo<void> {
  const ProfileRoute({List<_i34.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i20.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i21.PropertyDetailScreen]
class PropertyDetailRoute extends _i34.PageRouteInfo<PropertyDetailRouteArgs> {
  PropertyDetailRoute({
    _i35.Key? key,
    required _i37.PropertyModel property,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         PropertyDetailRoute.name,
         args: PropertyDetailRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'PropertyDetailRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyDetailRouteArgs>();
      return _i21.PropertyDetailScreen(key: args.key, property: args.property);
    },
  );
}

class PropertyDetailRouteArgs {
  const PropertyDetailRouteArgs({this.key, required this.property});

  final _i35.Key? key;

  final _i37.PropertyModel property;

  @override
  String toString() {
    return 'PropertyDetailRouteArgs{key: $key, property: $property}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PropertyDetailRouteArgs) return false;
    return key == other.key && property == other.property;
  }

  @override
  int get hashCode => key.hashCode ^ property.hashCode;
}

/// generated route for
/// [_i22.PropertyManagerProfileScreen]
class PropertyManagerProfileRoute
    extends _i34.PageRouteInfo<PropertyManagerProfileRouteArgs> {
  PropertyManagerProfileRoute({
    _i35.Key? key,
    bool isOnboarding = false,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         PropertyManagerProfileRoute.name,
         args: PropertyManagerProfileRouteArgs(
           key: key,
           isOnboarding: isOnboarding,
         ),
         initialChildren: children,
       );

  static const String name = 'PropertyManagerProfileRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyManagerProfileRouteArgs>(
        orElse: () => const PropertyManagerProfileRouteArgs(),
      );
      return _i22.PropertyManagerProfileScreen(
        key: args.key,
        isOnboarding: args.isOnboarding,
      );
    },
  );
}

class PropertyManagerProfileRouteArgs {
  const PropertyManagerProfileRouteArgs({this.key, this.isOnboarding = false});

  final _i35.Key? key;

  final bool isOnboarding;

  @override
  String toString() {
    return 'PropertyManagerProfileRouteArgs{key: $key, isOnboarding: $isOnboarding}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PropertyManagerProfileRouteArgs) return false;
    return key == other.key && isOnboarding == other.isOnboarding;
  }

  @override
  int get hashCode => key.hashCode ^ isOnboarding.hashCode;
}

/// generated route for
/// [_i23.PropertyScreen]
class PropertyRoute extends _i34.PageRouteInfo<void> {
  const PropertyRoute({List<_i34.PageRouteInfo>? children})
    : super(PropertyRoute.name, initialChildren: children);

  static const String name = 'PropertyRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i23.PropertyScreen();
    },
  );
}

/// generated route for
/// [_i24.RegisterScreen]
class RegisterRoute extends _i34.PageRouteInfo<void> {
  const RegisterRoute({List<_i34.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i24.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i25.ReportScreen]
class ReportRoute extends _i34.PageRouteInfo<void> {
  const ReportRoute({List<_i34.PageRouteInfo>? children})
    : super(ReportRoute.name, initialChildren: children);

  static const String name = 'ReportRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i25.ReportScreen();
    },
  );
}

/// generated route for
/// [_i26.ReservationScreen]
class ReservationRoute extends _i34.PageRouteInfo<void> {
  const ReservationRoute({List<_i34.PageRouteInfo>? children})
    : super(ReservationRoute.name, initialChildren: children);

  static const String name = 'ReservationRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i26.ReservationScreen();
    },
  );
}

/// generated route for
/// [_i27.ResidenceDetailScreen]
class ResidenceDetailRoute
    extends _i34.PageRouteInfo<ResidenceDetailRouteArgs> {
  ResidenceDetailRoute({
    _i35.Key? key,
    required String residenceId,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         ResidenceDetailRoute.name,
         args: ResidenceDetailRouteArgs(key: key, residenceId: residenceId),
         initialChildren: children,
       );

  static const String name = 'ResidenceDetailRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResidenceDetailRouteArgs>();
      return _i27.ResidenceDetailScreen(
        key: args.key,
        residenceId: args.residenceId,
      );
    },
  );
}

class ResidenceDetailRouteArgs {
  const ResidenceDetailRouteArgs({this.key, required this.residenceId});

  final _i35.Key? key;

  final String residenceId;

  @override
  String toString() {
    return 'ResidenceDetailRouteArgs{key: $key, residenceId: $residenceId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResidenceDetailRouteArgs) return false;
    return key == other.key && residenceId == other.residenceId;
  }

  @override
  int get hashCode => key.hashCode ^ residenceId.hashCode;
}

/// generated route for
/// [_i28.ResidenceScreen]
class ResidenceRoute extends _i34.PageRouteInfo<void> {
  const ResidenceRoute({List<_i34.PageRouteInfo>? children})
    : super(ResidenceRoute.name, initialChildren: children);

  static const String name = 'ResidenceRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i28.ResidenceScreen();
    },
  );
}

/// generated route for
/// [_i29.StayExtensionScreen]
class StayExtensionRoute extends _i34.PageRouteInfo<StayExtensionRouteArgs> {
  StayExtensionRoute({
    _i35.Key? key,
    required _i40.ReservationModel reservation,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         StayExtensionRoute.name,
         args: StayExtensionRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'StayExtensionRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StayExtensionRouteArgs>();
      return _i29.StayExtensionScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class StayExtensionRouteArgs {
  const StayExtensionRouteArgs({this.key, required this.reservation});

  final _i35.Key? key;

  final _i40.ReservationModel reservation;

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

/// generated route for
/// [_i30.SubscriptionPlansScreen]
class SubscriptionPlansRoute
    extends _i34.PageRouteInfo<SubscriptionPlansRouteArgs> {
  SubscriptionPlansRoute({
    bool blocking = false,
    _i35.Key? key,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         SubscriptionPlansRoute.name,
         args: SubscriptionPlansRouteArgs(blocking: blocking, key: key),
         initialChildren: children,
       );

  static const String name = 'SubscriptionPlansRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubscriptionPlansRouteArgs>(
        orElse: () => const SubscriptionPlansRouteArgs(),
      );
      return _i30.SubscriptionPlansScreen(
        blocking: args.blocking,
        key: args.key,
      );
    },
  );
}

class SubscriptionPlansRouteArgs {
  const SubscriptionPlansRouteArgs({this.blocking = false, this.key});

  final bool blocking;

  final _i35.Key? key;

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

/// generated route for
/// [_i31.SuccessScreen]
class SuccessRoute extends _i34.PageRouteInfo<SuccessRouteArgs> {
  SuccessRoute({
    _i35.Key? key,
    String title = 'Félicitations !',
    String subtitle = 'Votre bien a été enregistré avec succès',
    String buttonText = 'Voir mes biens',
    String secondaryButtonText = 'Ajouter un autre bien',
    int autoRedirectDuration = 5,
    _i35.VoidCallback? onPrimaryAction,
    _i35.VoidCallback? onSecondaryAction,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         SuccessRoute.name,
         args: SuccessRouteArgs(
           key: key,
           title: title,
           subtitle: subtitle,
           buttonText: buttonText,
           secondaryButtonText: secondaryButtonText,
           autoRedirectDuration: autoRedirectDuration,
           onPrimaryAction: onPrimaryAction,
           onSecondaryAction: onSecondaryAction,
         ),
         initialChildren: children,
       );

  static const String name = 'SuccessRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SuccessRouteArgs>(
        orElse: () => const SuccessRouteArgs(),
      );
      return _i31.SuccessScreen(
        key: args.key,
        title: args.title,
        subtitle: args.subtitle,
        buttonText: args.buttonText,
        secondaryButtonText: args.secondaryButtonText,
        autoRedirectDuration: args.autoRedirectDuration,
        onPrimaryAction: args.onPrimaryAction,
        onSecondaryAction: args.onSecondaryAction,
      );
    },
  );
}

class SuccessRouteArgs {
  const SuccessRouteArgs({
    this.key,
    this.title = 'Félicitations !',
    this.subtitle = 'Votre bien a été enregistré avec succès',
    this.buttonText = 'Voir mes biens',
    this.secondaryButtonText = 'Ajouter un autre bien',
    this.autoRedirectDuration = 5,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final _i35.Key? key;

  final String title;

  final String subtitle;

  final String buttonText;

  final String secondaryButtonText;

  final int autoRedirectDuration;

  final _i35.VoidCallback? onPrimaryAction;

  final _i35.VoidCallback? onSecondaryAction;

  @override
  String toString() {
    return 'SuccessRouteArgs{key: $key, title: $title, subtitle: $subtitle, buttonText: $buttonText, secondaryButtonText: $secondaryButtonText, autoRedirectDuration: $autoRedirectDuration, onPrimaryAction: $onPrimaryAction, onSecondaryAction: $onSecondaryAction}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SuccessRouteArgs) return false;
    return key == other.key &&
        title == other.title &&
        subtitle == other.subtitle &&
        buttonText == other.buttonText &&
        secondaryButtonText == other.secondaryButtonText &&
        autoRedirectDuration == other.autoRedirectDuration &&
        onPrimaryAction == other.onPrimaryAction &&
        onSecondaryAction == other.onSecondaryAction;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      buttonText.hashCode ^
      secondaryButtonText.hashCode ^
      autoRedirectDuration.hashCode ^
      onPrimaryAction.hashCode ^
      onSecondaryAction.hashCode;
}

/// generated route for
/// [_i32.SupportChatScreen]
class SupportChatRoute extends _i34.PageRouteInfo<SupportChatRouteArgs> {
  SupportChatRoute({
    _i35.Key? key,
    String? visitorName,
    String? visitorEmail,
    List<_i34.PageRouteInfo>? children,
  }) : super(
         SupportChatRoute.name,
         args: SupportChatRouteArgs(
           key: key,
           visitorName: visitorName,
           visitorEmail: visitorEmail,
         ),
         initialChildren: children,
       );

  static const String name = 'SupportChatRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SupportChatRouteArgs>(
        orElse: () => const SupportChatRouteArgs(),
      );
      return _i32.SupportChatScreen(
        key: args.key,
        visitorName: args.visitorName,
        visitorEmail: args.visitorEmail,
      );
    },
  );
}

class SupportChatRouteArgs {
  const SupportChatRouteArgs({this.key, this.visitorName, this.visitorEmail});

  final _i35.Key? key;

  final String? visitorName;

  final String? visitorEmail;

  @override
  String toString() {
    return 'SupportChatRouteArgs{key: $key, visitorName: $visitorName, visitorEmail: $visitorEmail}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SupportChatRouteArgs) return false;
    return key == other.key &&
        visitorName == other.visitorName &&
        visitorEmail == other.visitorEmail;
  }

  @override
  int get hashCode =>
      key.hashCode ^ visitorName.hashCode ^ visitorEmail.hashCode;
}

/// generated route for
/// [_i33.TrialWelcomeScreen]
class TrialWelcomeRoute extends _i34.PageRouteInfo<void> {
  const TrialWelcomeRoute({List<_i34.PageRouteInfo>? children})
    : super(TrialWelcomeRoute.name, initialChildren: children);

  static const String name = 'TrialWelcomeRoute';

  static _i34.PageInfo page = _i34.PageInfo(
    name,
    builder: (data) {
      return const _i33.TrialWelcomeScreen();
    },
  );
}
