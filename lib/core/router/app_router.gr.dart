// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i44;
import 'package:flutter/material.dart' as _i45;
import 'package:resi_africa/features/auth/presentation/screens/account_deletion_screen.dart'
    as _i1;
import 'package:resi_africa/features/auth/presentation/screens/auth_screen.dart'
    as _i10;
import 'package:resi_africa/features/auth/presentation/screens/forgot_password_screen.dart'
    as _i19;
import 'package:resi_africa/features/auth/presentation/screens/login_screen.dart'
    as _i23;
import 'package:resi_africa/features/auth/presentation/screens/property_manager_profile_screen.dart'
    as _i26;
import 'package:resi_africa/features/auth/presentation/screens/register_screen.dart'
    as _i28;
import 'package:resi_africa/features/auth/presentation/screens/trial_welcome_screen.dart'
    as _i41;
import 'package:resi_africa/features/clients/business_logic/client_detail_cubit.dart'
    as _i51;
import 'package:resi_africa/features/clients/data/models/client_model.dart'
    as _i49;
import 'package:resi_africa/features/clients/presentation/screens/add_client_screen.dart'
    as _i2;
import 'package:resi_africa/features/clients/presentation/screens/client_detail_screen.dart'
    as _i12;
import 'package:resi_africa/features/clients/presentation/screens/clients_screen.dart'
    as _i13;
import 'package:resi_africa/features/clients/presentation/screens/edit_client_screen.dart'
    as _i15;
import 'package:resi_africa/features/expense/data/models/expense_model.dart'
    as _i46;
import 'package:resi_africa/features/expense/presentation/screens/add_expense_screen.dart'
    as _i3;
import 'package:resi_africa/features/expense/presentation/screens/expense_screen.dart'
    as _i17;
import 'package:resi_africa/features/gerant/presentation/screens/add_gerant_screen.dart'
    as _i4;
import 'package:resi_africa/features/gerant/presentation/screens/change_password_screen.dart'
    as _i11;
import 'package:resi_africa/features/gerant/presentation/screens/gerant_list_screen.dart'
    as _i20;
import 'package:resi_africa/features/gerant/presentation/screens/gerant_scope_screen.dart'
    as _i21;
import 'package:resi_africa/features/home/presentation/screens/all_reviews_screen.dart'
    as _i8;
import 'package:resi_africa/features/home/presentation/screens/home_screen.dart'
    as _i22;
import 'package:resi_africa/features/home/presentation/widgets/tabs/profile_tab.dart'
    as _i24;
import 'package:resi_africa/features/property/data/models/property_model.dart'
    as _i47;
import 'package:resi_africa/features/property/presentation/screens/add_property_screen.dart'
    as _i5;
import 'package:resi_africa/features/property/presentation/screens/property_detail_screen.dart'
    as _i25;
import 'package:resi_africa/features/property/presentation/screens/property_screen.dart'
    as _i27;
import 'package:resi_africa/features/property/presentation/screens/success_screen.dart'
    as _i36;
import 'package:resi_africa/features/rapport/presentation/screens/rapport_screen.dart'
    as _i29;
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart'
    as _i48;
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart'
    as _i50;
import 'package:resi_africa/features/reservation/presentation/screens/add_reservation.dart'
    as _i6;
import 'package:resi_africa/features/reservation/presentation/screens/arrival_screen.dart'
    as _i9;
import 'package:resi_africa/features/reservation/presentation/screens/details_reservation_screen.dart'
    as _i14;
import 'package:resi_africa/features/reservation/presentation/screens/edit_reservation_screen.dart'
    as _i16;
import 'package:resi_africa/features/reservation/presentation/screens/reservation_screen.dart'
    as _i30;
import 'package:resi_africa/features/reservation/presentation/screens/stay_extension_screen.dart'
    as _i34;
import 'package:resi_africa/features/reservation/presentation/screens/sync_review_screen.dart'
    as _i38;
import 'package:resi_africa/features/residence/presentation/screens/add_residence_screen.dart'
    as _i7;
import 'package:resi_africa/features/residence/presentation/screens/residence_detail_screen.dart'
    as _i31;
import 'package:resi_africa/features/residence/presentation/screens/residence_screen.dart'
    as _i32;
import 'package:resi_africa/features/sponsorship/presentation/screens/sponsorship_screen.dart'
    as _i33;
import 'package:resi_africa/features/stats/presentation/screens/finance_screen.dart'
    as _i18;
import 'package:resi_africa/features/subscription/data/models/plan_access.dart'
    as _i52;
import 'package:resi_africa/features/subscription/presentation/screens/subscription_plans_screen.dart'
    as _i35;
import 'package:resi_africa/features/subscription/presentation/screens/trial_ended_screen.dart'
    as _i39;
import 'package:resi_africa/features/subscription/presentation/screens/trial_plan_choice_screen.dart'
    as _i40;
import 'package:resi_africa/features/support/presentation/screens/support_chat_screen.dart'
    as _i37;
import 'package:resi_africa/features/wallet/data/models/wallet_model.dart'
    as _i53;
import 'package:resi_africa/features/wallet/presentation/screens/wallet_screen.dart'
    as _i42;
import 'package:resi_africa/features/wallet/presentation/screens/wallet_transactions_screen.dart'
    as _i43;

/// generated route for
/// [_i1.AccountDeletionScreen]
class AccountDeletionRoute extends _i44.PageRouteInfo<void> {
  const AccountDeletionRoute({List<_i44.PageRouteInfo>? children})
    : super(AccountDeletionRoute.name, initialChildren: children);

  static const String name = 'AccountDeletionRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountDeletionScreen();
    },
  );
}

/// generated route for
/// [_i2.AddClientScreen]
class AddClientRoute extends _i44.PageRouteInfo<void> {
  const AddClientRoute({List<_i44.PageRouteInfo>? children})
    : super(AddClientRoute.name, initialChildren: children);

  static const String name = 'AddClientRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i2.AddClientScreen();
    },
  );
}

/// generated route for
/// [_i3.AddExpenseScreen]
class AddExpenseRoute extends _i44.PageRouteInfo<AddExpenseRouteArgs> {
  AddExpenseRoute({
    _i45.Key? key,
    _i46.ExpenseModel? expense,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         AddExpenseRoute.name,
         args: AddExpenseRouteArgs(key: key, expense: expense),
         initialChildren: children,
       );

  static const String name = 'AddExpenseRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddExpenseRouteArgs>(
        orElse: () => const AddExpenseRouteArgs(),
      );
      return _i3.AddExpenseScreen(key: args.key, expense: args.expense);
    },
  );
}

class AddExpenseRouteArgs {
  const AddExpenseRouteArgs({this.key, this.expense});

  final _i45.Key? key;

  final _i46.ExpenseModel? expense;

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
/// [_i4.AddGerantScreen]
class AddGerantRoute extends _i44.PageRouteInfo<void> {
  const AddGerantRoute({List<_i44.PageRouteInfo>? children})
    : super(AddGerantRoute.name, initialChildren: children);

  static const String name = 'AddGerantRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i4.AddGerantScreen();
    },
  );
}

/// generated route for
/// [_i5.AddPropertyScreen]
class AddPropertyRoute extends _i44.PageRouteInfo<AddPropertyRouteArgs> {
  AddPropertyRoute({
    _i45.Key? key,
    _i47.PropertyModel? property,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         AddPropertyRoute.name,
         args: AddPropertyRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'AddPropertyRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddPropertyRouteArgs>(
        orElse: () => const AddPropertyRouteArgs(),
      );
      return _i5.AddPropertyScreen(key: args.key, property: args.property);
    },
  );
}

class AddPropertyRouteArgs {
  const AddPropertyRouteArgs({this.key, this.property});

  final _i45.Key? key;

  final _i47.PropertyModel? property;

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
/// [_i6.AddReservationScreen]
class AddReservationRoute extends _i44.PageRouteInfo<AddReservationRouteArgs> {
  AddReservationRoute({
    _i48.ReservationMode mode = _i48.ReservationMode.checkIn,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         AddReservationRoute.name,
         args: AddReservationRouteArgs(mode: mode, key: key),
         initialChildren: children,
       );

  static const String name = 'AddReservationRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddReservationRouteArgs>(
        orElse: () => const AddReservationRouteArgs(),
      );
      return _i6.AddReservationScreen(mode: args.mode, key: args.key);
    },
  );
}

class AddReservationRouteArgs {
  const AddReservationRouteArgs({
    this.mode = _i48.ReservationMode.checkIn,
    this.key,
  });

  final _i48.ReservationMode mode;

  final _i45.Key? key;

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
/// [_i7.AddResidenceScreen]
class AddResidenceRoute extends _i44.PageRouteInfo<AddResidenceRouteArgs> {
  AddResidenceRoute({
    _i45.Key? key,
    String? residenceId,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         AddResidenceRoute.name,
         args: AddResidenceRouteArgs(key: key, residenceId: residenceId),
         rawQueryParams: {'id': residenceId},
         initialChildren: children,
       );

  static const String name = 'AddResidenceRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AddResidenceRouteArgs>(
        orElse: () =>
            AddResidenceRouteArgs(residenceId: queryParams.optString('id')),
      );
      return _i7.AddResidenceScreen(
        key: args.key,
        residenceId: args.residenceId,
      );
    },
  );
}

class AddResidenceRouteArgs {
  const AddResidenceRouteArgs({this.key, this.residenceId});

  final _i45.Key? key;

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
/// [_i8.AllReviewsScreen]
class AllReviewsRoute extends _i44.PageRouteInfo<void> {
  const AllReviewsRoute({List<_i44.PageRouteInfo>? children})
    : super(AllReviewsRoute.name, initialChildren: children);

  static const String name = 'AllReviewsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i8.AllReviewsScreen();
    },
  );
}

/// generated route for
/// [_i9.ArrivalScreen]
class ArrivalRoute extends _i44.PageRouteInfo<void> {
  const ArrivalRoute({List<_i44.PageRouteInfo>? children})
    : super(ArrivalRoute.name, initialChildren: children);

  static const String name = 'ArrivalRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i9.ArrivalScreen();
    },
  );
}

/// generated route for
/// [_i10.AuthScreen]
class AuthRoute extends _i44.PageRouteInfo<void> {
  const AuthRoute({List<_i44.PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i10.AuthScreen();
    },
  );
}

/// generated route for
/// [_i11.ChangePasswordScreen]
class ChangePasswordRoute extends _i44.PageRouteInfo<ChangePasswordRouteArgs> {
  ChangePasswordRoute({
    String? phone,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         ChangePasswordRoute.name,
         args: ChangePasswordRouteArgs(phone: phone, key: key),
         initialChildren: children,
       );

  static const String name = 'ChangePasswordRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChangePasswordRouteArgs>(
        orElse: () => const ChangePasswordRouteArgs(),
      );
      return _i11.ChangePasswordScreen(phone: args.phone, key: args.key);
    },
  );
}

class ChangePasswordRouteArgs {
  const ChangePasswordRouteArgs({this.phone, this.key});

  final String? phone;

  final _i45.Key? key;

  @override
  String toString() {
    return 'ChangePasswordRouteArgs{phone: $phone, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChangePasswordRouteArgs) return false;
    return phone == other.phone && key == other.key;
  }

  @override
  int get hashCode => phone.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i12.ClientDetailScreen]
class ClientDetailRoute extends _i44.PageRouteInfo<ClientDetailRouteArgs> {
  ClientDetailRoute({
    _i45.Key? key,
    required _i49.ClientModel client,
    _i45.VoidCallback? onArchiveToggle,
    List<_i44.PageRouteInfo>? children,
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

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ClientDetailRouteArgs>();
      return _i12.ClientDetailScreen(
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

  final _i45.Key? key;

  final _i49.ClientModel client;

  final _i45.VoidCallback? onArchiveToggle;

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
/// [_i13.ClientsScreen]
class ClientsRoute extends _i44.PageRouteInfo<void> {
  const ClientsRoute({List<_i44.PageRouteInfo>? children})
    : super(ClientsRoute.name, initialChildren: children);

  static const String name = 'ClientsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i13.ClientsScreen();
    },
  );
}

/// generated route for
/// [_i14.DetailsReservationScreen]
class DetailsReservationRoute
    extends _i44.PageRouteInfo<DetailsReservationRouteArgs> {
  DetailsReservationRoute({
    _i45.Key? key,
    required _i50.ReservationModel reservation,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         DetailsReservationRoute.name,
         args: DetailsReservationRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'DetailsReservationRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailsReservationRouteArgs>();
      return _i14.DetailsReservationScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class DetailsReservationRouteArgs {
  const DetailsReservationRouteArgs({this.key, required this.reservation});

  final _i45.Key? key;

  final _i50.ReservationModel reservation;

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
/// [_i15.EditClientScreen]
class EditClientRoute extends _i44.PageRouteInfo<EditClientRouteArgs> {
  EditClientRoute({
    _i45.Key? key,
    required _i49.ClientModel client,
    required _i51.ClientDetailCubit cubit,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         EditClientRoute.name,
         args: EditClientRouteArgs(key: key, client: client, cubit: cubit),
         initialChildren: children,
       );

  static const String name = 'EditClientRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditClientRouteArgs>();
      return _i15.EditClientScreen(
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

  final _i45.Key? key;

  final _i49.ClientModel client;

  final _i51.ClientDetailCubit cubit;

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
/// [_i16.EditReservationScreen]
class EditReservationRoute
    extends _i44.PageRouteInfo<EditReservationRouteArgs> {
  EditReservationRoute({
    required _i50.ReservationModel reservation,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         EditReservationRoute.name,
         args: EditReservationRouteArgs(reservation: reservation, key: key),
         initialChildren: children,
       );

  static const String name = 'EditReservationRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditReservationRouteArgs>();
      return _i16.EditReservationScreen(
        reservation: args.reservation,
        key: args.key,
      );
    },
  );
}

class EditReservationRouteArgs {
  const EditReservationRouteArgs({required this.reservation, this.key});

  final _i50.ReservationModel reservation;

  final _i45.Key? key;

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
/// [_i17.ExpenseScreen]
class ExpenseRoute extends _i44.PageRouteInfo<void> {
  const ExpenseRoute({List<_i44.PageRouteInfo>? children})
    : super(ExpenseRoute.name, initialChildren: children);

  static const String name = 'ExpenseRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i17.ExpenseScreen();
    },
  );
}

/// generated route for
/// [_i18.FinanceScreen]
class FinanceRoute extends _i44.PageRouteInfo<void> {
  const FinanceRoute({List<_i44.PageRouteInfo>? children})
    : super(FinanceRoute.name, initialChildren: children);

  static const String name = 'FinanceRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i18.FinanceScreen();
    },
  );
}

/// generated route for
/// [_i19.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i44.PageRouteInfo<ForgotPasswordRouteArgs> {
  ForgotPasswordRoute({
    String? identifier,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         ForgotPasswordRoute.name,
         args: ForgotPasswordRouteArgs(identifier: identifier, key: key),
         initialChildren: children,
       );

  static const String name = 'ForgotPasswordRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ForgotPasswordRouteArgs>(
        orElse: () => const ForgotPasswordRouteArgs(),
      );
      return _i19.ForgotPasswordScreen(
        identifier: args.identifier,
        key: args.key,
      );
    },
  );
}

class ForgotPasswordRouteArgs {
  const ForgotPasswordRouteArgs({this.identifier, this.key});

  final String? identifier;

  final _i45.Key? key;

  @override
  String toString() {
    return 'ForgotPasswordRouteArgs{identifier: $identifier, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ForgotPasswordRouteArgs) return false;
    return identifier == other.identifier && key == other.key;
  }

  @override
  int get hashCode => identifier.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i20.GerantListScreen]
class GerantListRoute extends _i44.PageRouteInfo<void> {
  const GerantListRoute({List<_i44.PageRouteInfo>? children})
    : super(GerantListRoute.name, initialChildren: children);

  static const String name = 'GerantListRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i20.GerantListScreen();
    },
  );
}

/// generated route for
/// [_i21.GerantScopeScreen]
class GerantScopeRoute extends _i44.PageRouteInfo<GerantScopeRouteArgs> {
  GerantScopeRoute({
    _i45.Key? key,
    required String gerantId,
    String? gerantName,
    List<_i44.PageRouteInfo>? children,
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

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<GerantScopeRouteArgs>();
      return _i21.GerantScopeScreen(
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

  final _i45.Key? key;

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
/// [_i22.HomeScreen]
class HomeRoute extends _i44.PageRouteInfo<void> {
  const HomeRoute({List<_i44.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i22.HomeScreen();
    },
  );
}

/// generated route for
/// [_i23.LoginScreen]
class LoginRoute extends _i44.PageRouteInfo<void> {
  const LoginRoute({List<_i44.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i23.LoginScreen();
    },
  );
}

/// generated route for
/// [_i24.ProfileScreen]
class ProfileRoute extends _i44.PageRouteInfo<void> {
  const ProfileRoute({List<_i44.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i24.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i25.PropertyDetailScreen]
class PropertyDetailRoute extends _i44.PageRouteInfo<PropertyDetailRouteArgs> {
  PropertyDetailRoute({
    _i45.Key? key,
    required _i47.PropertyModel property,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         PropertyDetailRoute.name,
         args: PropertyDetailRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'PropertyDetailRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyDetailRouteArgs>();
      return _i25.PropertyDetailScreen(key: args.key, property: args.property);
    },
  );
}

class PropertyDetailRouteArgs {
  const PropertyDetailRouteArgs({this.key, required this.property});

  final _i45.Key? key;

  final _i47.PropertyModel property;

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
/// [_i26.PropertyManagerProfileScreen]
class PropertyManagerProfileRoute
    extends _i44.PageRouteInfo<PropertyManagerProfileRouteArgs> {
  PropertyManagerProfileRoute({
    _i45.Key? key,
    bool isOnboarding = false,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         PropertyManagerProfileRoute.name,
         args: PropertyManagerProfileRouteArgs(
           key: key,
           isOnboarding: isOnboarding,
         ),
         initialChildren: children,
       );

  static const String name = 'PropertyManagerProfileRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyManagerProfileRouteArgs>(
        orElse: () => const PropertyManagerProfileRouteArgs(),
      );
      return _i26.PropertyManagerProfileScreen(
        key: args.key,
        isOnboarding: args.isOnboarding,
      );
    },
  );
}

class PropertyManagerProfileRouteArgs {
  const PropertyManagerProfileRouteArgs({this.key, this.isOnboarding = false});

  final _i45.Key? key;

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
/// [_i27.PropertyScreen]
class PropertyRoute extends _i44.PageRouteInfo<void> {
  const PropertyRoute({List<_i44.PageRouteInfo>? children})
    : super(PropertyRoute.name, initialChildren: children);

  static const String name = 'PropertyRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i27.PropertyScreen();
    },
  );
}

/// generated route for
/// [_i28.RegisterScreen]
class RegisterRoute extends _i44.PageRouteInfo<void> {
  const RegisterRoute({List<_i44.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i28.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i29.ReportScreen]
class ReportRoute extends _i44.PageRouteInfo<void> {
  const ReportRoute({List<_i44.PageRouteInfo>? children})
    : super(ReportRoute.name, initialChildren: children);

  static const String name = 'ReportRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i29.ReportScreen();
    },
  );
}

/// generated route for
/// [_i30.ReservationScreen]
class ReservationRoute extends _i44.PageRouteInfo<void> {
  const ReservationRoute({List<_i44.PageRouteInfo>? children})
    : super(ReservationRoute.name, initialChildren: children);

  static const String name = 'ReservationRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i30.ReservationScreen();
    },
  );
}

/// generated route for
/// [_i31.ResidenceDetailScreen]
class ResidenceDetailRoute
    extends _i44.PageRouteInfo<ResidenceDetailRouteArgs> {
  ResidenceDetailRoute({
    _i45.Key? key,
    required String residenceId,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         ResidenceDetailRoute.name,
         args: ResidenceDetailRouteArgs(key: key, residenceId: residenceId),
         initialChildren: children,
       );

  static const String name = 'ResidenceDetailRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResidenceDetailRouteArgs>();
      return _i31.ResidenceDetailScreen(
        key: args.key,
        residenceId: args.residenceId,
      );
    },
  );
}

class ResidenceDetailRouteArgs {
  const ResidenceDetailRouteArgs({this.key, required this.residenceId});

  final _i45.Key? key;

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
/// [_i32.ResidenceScreen]
class ResidenceRoute extends _i44.PageRouteInfo<void> {
  const ResidenceRoute({List<_i44.PageRouteInfo>? children})
    : super(ResidenceRoute.name, initialChildren: children);

  static const String name = 'ResidenceRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i32.ResidenceScreen();
    },
  );
}

/// generated route for
/// [_i33.SponsorshipScreen]
class SponsorshipRoute extends _i44.PageRouteInfo<void> {
  const SponsorshipRoute({List<_i44.PageRouteInfo>? children})
    : super(SponsorshipRoute.name, initialChildren: children);

  static const String name = 'SponsorshipRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i33.SponsorshipScreen();
    },
  );
}

/// generated route for
/// [_i34.StayExtensionScreen]
class StayExtensionRoute extends _i44.PageRouteInfo<StayExtensionRouteArgs> {
  StayExtensionRoute({
    _i45.Key? key,
    required _i50.ReservationModel reservation,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         StayExtensionRoute.name,
         args: StayExtensionRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'StayExtensionRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StayExtensionRouteArgs>();
      return _i34.StayExtensionScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class StayExtensionRouteArgs {
  const StayExtensionRouteArgs({this.key, required this.reservation});

  final _i45.Key? key;

  final _i50.ReservationModel reservation;

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
/// [_i35.SubscriptionPlansScreen]
class SubscriptionPlansRoute
    extends _i44.PageRouteInfo<SubscriptionPlansRouteArgs> {
  SubscriptionPlansRoute({
    bool blocking = false,
    _i52.PlanAccess? focus,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
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

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubscriptionPlansRouteArgs>(
        orElse: () => const SubscriptionPlansRouteArgs(),
      );
      return _i35.SubscriptionPlansScreen(
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

  final _i52.PlanAccess? focus;

  final _i45.Key? key;

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
/// [_i36.SuccessScreen]
class SuccessRoute extends _i44.PageRouteInfo<SuccessRouteArgs> {
  SuccessRoute({
    _i45.Key? key,
    String? title,
    String? subtitle,
    String? buttonText,
    String? secondaryButtonText,
    int autoRedirectDuration = 5,
    _i45.VoidCallback? onPrimaryAction,
    _i45.VoidCallback? onSecondaryAction,
    List<_i44.PageRouteInfo>? children,
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

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SuccessRouteArgs>(
        orElse: () => const SuccessRouteArgs(),
      );
      return _i36.SuccessScreen(
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
    this.title,
    this.subtitle,
    this.buttonText,
    this.secondaryButtonText,
    this.autoRedirectDuration = 5,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final _i45.Key? key;

  final String? title;

  final String? subtitle;

  final String? buttonText;

  final String? secondaryButtonText;

  final int autoRedirectDuration;

  final _i45.VoidCallback? onPrimaryAction;

  final _i45.VoidCallback? onSecondaryAction;

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
/// [_i37.SupportChatScreen]
class SupportChatRoute extends _i44.PageRouteInfo<SupportChatRouteArgs> {
  SupportChatRoute({
    _i45.Key? key,
    String? visitorName,
    String? visitorEmail,
    List<_i44.PageRouteInfo>? children,
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

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SupportChatRouteArgs>(
        orElse: () => const SupportChatRouteArgs(),
      );
      return _i37.SupportChatScreen(
        key: args.key,
        visitorName: args.visitorName,
        visitorEmail: args.visitorEmail,
      );
    },
  );
}

class SupportChatRouteArgs {
  const SupportChatRouteArgs({this.key, this.visitorName, this.visitorEmail});

  final _i45.Key? key;

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
/// [_i38.SyncReviewScreen]
class SyncReviewRoute extends _i44.PageRouteInfo<void> {
  const SyncReviewRoute({List<_i44.PageRouteInfo>? children})
    : super(SyncReviewRoute.name, initialChildren: children);

  static const String name = 'SyncReviewRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i38.SyncReviewScreen();
    },
  );
}

/// generated route for
/// [_i39.TrialEndedScreen]
class TrialEndedRoute extends _i44.PageRouteInfo<TrialEndedRouteArgs> {
  TrialEndedRoute({
    required _i52.PlanAccess tier,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         TrialEndedRoute.name,
         args: TrialEndedRouteArgs(tier: tier, key: key),
         initialChildren: children,
       );

  static const String name = 'TrialEndedRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TrialEndedRouteArgs>();
      return _i39.TrialEndedScreen(tier: args.tier, key: args.key);
    },
  );
}

class TrialEndedRouteArgs {
  const TrialEndedRouteArgs({required this.tier, this.key});

  final _i52.PlanAccess tier;

  final _i45.Key? key;

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
/// [_i40.TrialPlanChoiceScreen]
class TrialPlanChoiceRoute extends _i44.PageRouteInfo<void> {
  const TrialPlanChoiceRoute({List<_i44.PageRouteInfo>? children})
    : super(TrialPlanChoiceRoute.name, initialChildren: children);

  static const String name = 'TrialPlanChoiceRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i40.TrialPlanChoiceScreen();
    },
  );
}

/// generated route for
/// [_i41.TrialWelcomeScreen]
class TrialWelcomeRoute extends _i44.PageRouteInfo<void> {
  const TrialWelcomeRoute({List<_i44.PageRouteInfo>? children})
    : super(TrialWelcomeRoute.name, initialChildren: children);

  static const String name = 'TrialWelcomeRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i41.TrialWelcomeScreen();
    },
  );
}

/// generated route for
/// [_i42.WalletScreen]
class WalletRoute extends _i44.PageRouteInfo<void> {
  const WalletRoute({List<_i44.PageRouteInfo>? children})
    : super(WalletRoute.name, initialChildren: children);

  static const String name = 'WalletRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      return const _i42.WalletScreen();
    },
  );
}

/// generated route for
/// [_i43.WalletTransactionsScreen]
class WalletTransactionsRoute
    extends _i44.PageRouteInfo<WalletTransactionsRouteArgs> {
  WalletTransactionsRoute({
    required _i53.WalletModel wallet,
    _i45.Key? key,
    List<_i44.PageRouteInfo>? children,
  }) : super(
         WalletTransactionsRoute.name,
         args: WalletTransactionsRouteArgs(wallet: wallet, key: key),
         initialChildren: children,
       );

  static const String name = 'WalletTransactionsRoute';

  static _i44.PageInfo page = _i44.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WalletTransactionsRouteArgs>();
      return _i43.WalletTransactionsScreen(wallet: args.wallet, key: args.key);
    },
  );
}

class WalletTransactionsRouteArgs {
  const WalletTransactionsRouteArgs({required this.wallet, this.key});

  final _i53.WalletModel wallet;

  final _i45.Key? key;

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
