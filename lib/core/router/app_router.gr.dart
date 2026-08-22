// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i25;
import 'package:flutter/material.dart' as _i26;
import 'package:resi_africa/features/auth/presentation/screens/auth_screen.dart'
    as _i6;
import 'package:resi_africa/features/auth/presentation/screens/login_screen.dart'
    as _i13;
import 'package:resi_africa/features/auth/presentation/screens/property_manager_profile_screen.dart'
    as _i16;
import 'package:resi_africa/features/auth/presentation/screens/register_screen.dart'
    as _i18;
import 'package:resi_africa/features/auth/presentation/screens/trial_welcome_screen.dart'
    as _i24;
import 'package:resi_africa/features/clients/data/models/client_model.dart'
    as _i28;
import 'package:resi_africa/features/clients/presentation/screens/add_client_screen.dart'
    as _i1;
import 'package:resi_africa/features/clients/presentation/screens/client_detail_screen.dart'
    as _i7;
import 'package:resi_africa/features/clients/presentation/screens/clients_screen.dart'
    as _i8;
import 'package:resi_africa/features/expense/data/models/expense_model.dart'
    as _i27;
import 'package:resi_africa/features/expense/presentation/screens/add_expense_screen.dart'
    as _i2;
import 'package:resi_africa/features/expense/presentation/screens/expense_screen.dart'
    as _i10;
import 'package:resi_africa/features/home/presentation/screens/all_reviews_screen.dart'
    as _i5;
import 'package:resi_africa/features/home/presentation/screens/home_screen.dart'
    as _i12;
import 'package:resi_africa/features/home/presentation/widgets/tabs/profile_tab.dart'
    as _i14;
import 'package:resi_africa/features/property/data/models/property_model.dart'
    as _i30;
import 'package:resi_africa/features/property/presentation/screens/add_property_screen.dart'
    as _i3;
import 'package:resi_africa/features/property/presentation/screens/property_detail_screen.dart'
    as _i15;
import 'package:resi_africa/features/property/presentation/screens/property_screen.dart'
    as _i17;
import 'package:resi_africa/features/property/presentation/screens/success_screen.dart'
    as _i22;
import 'package:resi_africa/features/rapport/presentation/screens/rapport_screen.dart'
    as _i19;
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart'
    as _i31;
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart'
    as _i29;
import 'package:resi_africa/features/reservation/presentation/screens/add_reservation.dart'
    as _i4;
import 'package:resi_africa/features/reservation/presentation/screens/details_reservation_screen.dart'
    as _i9;
import 'package:resi_africa/features/reservation/presentation/screens/reservation_screen.dart'
    as _i20;
import 'package:resi_africa/features/reservation/presentation/screens/stay_extension_screen.dart'
    as _i21;
import 'package:resi_africa/features/stats/presentation/screens/finance_screen.dart'
    as _i11;
import 'package:resi_africa/features/support/presentation/screens/support_chat_screen.dart'
    as _i23;

/// generated route for
/// [_i1.AddClientScreen]
class AddClientRoute extends _i25.PageRouteInfo<void> {
  const AddClientRoute({List<_i25.PageRouteInfo>? children})
    : super(AddClientRoute.name, initialChildren: children);

  static const String name = 'AddClientRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddClientScreen();
    },
  );
}

/// generated route for
/// [_i2.AddExpenseScreen]
class AddExpenseRoute extends _i25.PageRouteInfo<AddExpenseRouteArgs> {
  AddExpenseRoute({
    _i26.Key? key,
    _i27.ExpenseModel? expense,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         AddExpenseRoute.name,
         args: AddExpenseRouteArgs(key: key, expense: expense),
         initialChildren: children,
       );

  static const String name = 'AddExpenseRoute';

  static _i25.PageInfo page = _i25.PageInfo(
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

  final _i26.Key? key;

  final _i27.ExpenseModel? expense;

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
/// [_i3.AddPropertyScreen]
class AddPropertyRoute extends _i25.PageRouteInfo<void> {
  const AddPropertyRoute({List<_i25.PageRouteInfo>? children})
    : super(AddPropertyRoute.name, initialChildren: children);

  static const String name = 'AddPropertyRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddPropertyScreen();
    },
  );
}

/// generated route for
/// [_i4.AddReservationScreen]
class AddReservationRoute extends _i25.PageRouteInfo<AddReservationRouteArgs> {
  AddReservationRoute({
    _i26.Key? key,
    _i31.ReservationMode mode = _i31.ReservationMode.checkIn,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         AddReservationRoute.name,
         args: AddReservationRouteArgs(key: key, mode: mode),
         initialChildren: children,
       );

  static const String name = 'AddReservationRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddReservationRouteArgs>(
        orElse: () => const AddReservationRouteArgs(),
      );
      return _i4.AddReservationScreen(key: args.key, mode: args.mode);
    },
  );
}

class AddReservationRouteArgs {
  const AddReservationRouteArgs({
    this.key,
    this.mode = _i31.ReservationMode.checkIn,
  });

  final _i26.Key? key;

  final _i31.ReservationMode mode;

  @override
  String toString() {
    return 'AddReservationRouteArgs{key: $key, mode: $mode}';
  }
}

/// generated route for
/// [_i5.AllReviewsScreen]
class AllReviewsRoute extends _i25.PageRouteInfo<void> {
  const AllReviewsRoute({List<_i25.PageRouteInfo>? children})
    : super(AllReviewsRoute.name, initialChildren: children);

  static const String name = 'AllReviewsRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i5.AllReviewsScreen();
    },
  );
}

/// generated route for
/// [_i6.AuthScreen]
class AuthRoute extends _i25.PageRouteInfo<void> {
  const AuthRoute({List<_i25.PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i6.AuthScreen();
    },
  );
}

/// generated route for
/// [_i7.ClientDetailScreen]
class ClientDetailRoute extends _i25.PageRouteInfo<ClientDetailRouteArgs> {
  ClientDetailRoute({
    _i26.Key? key,
    required _i28.ClientModel client,
    _i26.VoidCallback? onArchiveToggle,
    List<_i25.PageRouteInfo>? children,
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

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ClientDetailRouteArgs>();
      return _i7.ClientDetailScreen(
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

  final _i26.Key? key;

  final _i28.ClientModel client;

  final _i26.VoidCallback? onArchiveToggle;

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
/// [_i8.ClientsScreen]
class ClientsRoute extends _i25.PageRouteInfo<void> {
  const ClientsRoute({List<_i25.PageRouteInfo>? children})
    : super(ClientsRoute.name, initialChildren: children);

  static const String name = 'ClientsRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i8.ClientsScreen();
    },
  );
}

/// generated route for
/// [_i9.DetailsReservationScreen]
class DetailsReservationRoute
    extends _i25.PageRouteInfo<DetailsReservationRouteArgs> {
  DetailsReservationRoute({
    _i26.Key? key,
    required _i29.ReservationModel reservation,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         DetailsReservationRoute.name,
         args: DetailsReservationRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'DetailsReservationRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailsReservationRouteArgs>();
      return _i9.DetailsReservationScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class DetailsReservationRouteArgs {
  const DetailsReservationRouteArgs({this.key, required this.reservation});

  final _i26.Key? key;

  final _i29.ReservationModel reservation;

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
/// [_i10.ExpenseScreen]
class ExpenseRoute extends _i25.PageRouteInfo<void> {
  const ExpenseRoute({List<_i25.PageRouteInfo>? children})
    : super(ExpenseRoute.name, initialChildren: children);

  static const String name = 'ExpenseRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i10.ExpenseScreen();
    },
  );
}

/// generated route for
/// [_i11.FinanceScreen]
class FinanceRoute extends _i25.PageRouteInfo<void> {
  const FinanceRoute({List<_i25.PageRouteInfo>? children})
    : super(FinanceRoute.name, initialChildren: children);

  static const String name = 'FinanceRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i11.FinanceScreen();
    },
  );
}

/// generated route for
/// [_i12.HomeScreen]
class HomeRoute extends _i25.PageRouteInfo<void> {
  const HomeRoute({List<_i25.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i12.HomeScreen();
    },
  );
}

/// generated route for
/// [_i13.LoginScreen]
class LoginRoute extends _i25.PageRouteInfo<void> {
  const LoginRoute({List<_i25.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i13.LoginScreen();
    },
  );
}

/// generated route for
/// [_i14.ProfileScreen]
class ProfileRoute extends _i25.PageRouteInfo<void> {
  const ProfileRoute({List<_i25.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i14.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i15.PropertyDetailScreen]
class PropertyDetailRoute extends _i25.PageRouteInfo<PropertyDetailRouteArgs> {
  PropertyDetailRoute({
    _i26.Key? key,
    required _i30.PropertyModel property,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         PropertyDetailRoute.name,
         args: PropertyDetailRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'PropertyDetailRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyDetailRouteArgs>();
      return _i15.PropertyDetailScreen(key: args.key, property: args.property);
    },
  );
}

class PropertyDetailRouteArgs {
  const PropertyDetailRouteArgs({this.key, required this.property});

  final _i26.Key? key;

  final _i30.PropertyModel property;

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
/// [_i16.PropertyManagerProfileScreen]
class PropertyManagerProfileRoute
    extends _i25.PageRouteInfo<PropertyManagerProfileRouteArgs> {
  PropertyManagerProfileRoute({
    _i26.Key? key,
    bool isOnboarding = false,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         PropertyManagerProfileRoute.name,
         args: PropertyManagerProfileRouteArgs(
           key: key,
           isOnboarding: isOnboarding,
         ),
         initialChildren: children,
       );

  static const String name = 'PropertyManagerProfileRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyManagerProfileRouteArgs>(
        orElse: () => const PropertyManagerProfileRouteArgs(),
      );
      return _i16.PropertyManagerProfileScreen(
        key: args.key,
        isOnboarding: args.isOnboarding,
      );
    },
  );
}

class PropertyManagerProfileRouteArgs {
  const PropertyManagerProfileRouteArgs({this.key, this.isOnboarding = false});

  final _i26.Key? key;

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
/// [_i17.PropertyScreen]
class PropertyRoute extends _i25.PageRouteInfo<void> {
  const PropertyRoute({List<_i25.PageRouteInfo>? children})
    : super(PropertyRoute.name, initialChildren: children);

  static const String name = 'PropertyRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i17.PropertyScreen();
    },
  );
}

/// generated route for
/// [_i18.RegisterScreen]
class RegisterRoute extends _i25.PageRouteInfo<void> {
  const RegisterRoute({List<_i25.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i18.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i19.ReportScreen]
class ReportRoute extends _i25.PageRouteInfo<void> {
  const ReportRoute({List<_i25.PageRouteInfo>? children})
    : super(ReportRoute.name, initialChildren: children);

  static const String name = 'ReportRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i19.ReportScreen();
    },
  );
}

/// generated route for
/// [_i20.ReservationScreen]
class ReservationRoute extends _i25.PageRouteInfo<void> {
  const ReservationRoute({List<_i25.PageRouteInfo>? children})
    : super(ReservationRoute.name, initialChildren: children);

  static const String name = 'ReservationRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i20.ReservationScreen();
    },
  );
}

/// generated route for
/// [_i21.StayExtensionScreen]
class StayExtensionRoute extends _i25.PageRouteInfo<StayExtensionRouteArgs> {
  StayExtensionRoute({
    _i26.Key? key,
    required _i29.ReservationModel reservation,
    List<_i25.PageRouteInfo>? children,
  }) : super(
         StayExtensionRoute.name,
         args: StayExtensionRouteArgs(key: key, reservation: reservation),
         initialChildren: children,
       );

  static const String name = 'StayExtensionRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StayExtensionRouteArgs>();
      return _i21.StayExtensionScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class StayExtensionRouteArgs {
  const StayExtensionRouteArgs({this.key, required this.reservation});

  final _i26.Key? key;

  final _i29.ReservationModel reservation;

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
/// [_i22.SuccessScreen]
class SuccessRoute extends _i25.PageRouteInfo<SuccessRouteArgs> {
  SuccessRoute({
    _i26.Key? key,
    String title = 'Félicitations !',
    String subtitle = 'Votre bien a été enregistré avec succès',
    String buttonText = 'Voir mes biens',
    String secondaryButtonText = 'Ajouter un autre bien',
    int autoRedirectDuration = 5,
    _i26.VoidCallback? onPrimaryAction,
    _i26.VoidCallback? onSecondaryAction,
    List<_i25.PageRouteInfo>? children,
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

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SuccessRouteArgs>(
        orElse: () => const SuccessRouteArgs(),
      );
      return _i22.SuccessScreen(
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

  final _i26.Key? key;

  final String title;

  final String subtitle;

  final String buttonText;

  final String secondaryButtonText;

  final int autoRedirectDuration;

  final _i26.VoidCallback? onPrimaryAction;

  final _i26.VoidCallback? onSecondaryAction;

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
/// [_i23.SupportChatScreen]
class SupportChatRoute extends _i25.PageRouteInfo<SupportChatRouteArgs> {
  SupportChatRoute({
    _i26.Key? key,
    String? visitorName,
    String? visitorEmail,
    List<_i25.PageRouteInfo>? children,
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

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SupportChatRouteArgs>(
        orElse: () => const SupportChatRouteArgs(),
      );
      return _i23.SupportChatScreen(
        key: args.key,
        visitorName: args.visitorName,
        visitorEmail: args.visitorEmail,
      );
    },
  );
}

class SupportChatRouteArgs {
  const SupportChatRouteArgs({this.key, this.visitorName, this.visitorEmail});

  final _i26.Key? key;

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
/// [_i24.TrialWelcomeScreen]
class TrialWelcomeRoute extends _i25.PageRouteInfo<void> {
  const TrialWelcomeRoute({List<_i25.PageRouteInfo>? children})
    : super(TrialWelcomeRoute.name, initialChildren: children);

  static const String name = 'TrialWelcomeRoute';

  static _i25.PageInfo page = _i25.PageInfo(
    name,
    builder: (data) {
      return const _i24.TrialWelcomeScreen();
    },
  );
}
