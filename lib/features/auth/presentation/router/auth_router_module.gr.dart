// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i9;
import 'package:resi_africa/features/auth/presentation/screens/account_deletion_screen.dart'
    as _i1;
import 'package:resi_africa/features/auth/presentation/screens/auth_screen.dart'
    as _i2;
import 'package:resi_africa/features/auth/presentation/screens/forgot_password_screen.dart'
    as _i3;
import 'package:resi_africa/features/auth/presentation/screens/login_screen.dart'
    as _i4;
import 'package:resi_africa/features/auth/presentation/screens/property_manager_profile_screen.dart'
    as _i5;
import 'package:resi_africa/features/auth/presentation/screens/register_screen.dart'
    as _i6;
import 'package:resi_africa/features/auth/presentation/screens/trial_welcome_screen.dart'
    as _i7;

/// generated route for
/// [_i1.AccountDeletionScreen]
class AccountDeletionRoute extends _i8.PageRouteInfo<void> {
  const AccountDeletionRoute({List<_i8.PageRouteInfo>? children})
    : super(AccountDeletionRoute.name, initialChildren: children);

  static const String name = 'AccountDeletionRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i1.AccountDeletionScreen();
    },
  );
}

/// generated route for
/// [_i2.AuthScreen]
class AuthRoute extends _i8.PageRouteInfo<void> {
  const AuthRoute({List<_i8.PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i2.AuthScreen();
    },
  );
}

/// generated route for
/// [_i3.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i8.PageRouteInfo<ForgotPasswordRouteArgs> {
  ForgotPasswordRoute({
    String? identifier,
    _i9.Key? key,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         ForgotPasswordRoute.name,
         args: ForgotPasswordRouteArgs(identifier: identifier, key: key),
         initialChildren: children,
       );

  static const String name = 'ForgotPasswordRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ForgotPasswordRouteArgs>(
        orElse: () => const ForgotPasswordRouteArgs(),
      );
      return _i3.ForgotPasswordScreen(
        identifier: args.identifier,
        key: args.key,
      );
    },
  );
}

class ForgotPasswordRouteArgs {
  const ForgotPasswordRouteArgs({this.identifier, this.key});

  final String? identifier;

  final _i9.Key? key;

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
/// [_i4.LoginScreen]
class LoginRoute extends _i8.PageRouteInfo<void> {
  const LoginRoute({List<_i8.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i4.LoginScreen();
    },
  );
}

/// generated route for
/// [_i5.PropertyManagerProfileScreen]
class PropertyManagerProfileRoute
    extends _i8.PageRouteInfo<PropertyManagerProfileRouteArgs> {
  PropertyManagerProfileRoute({
    _i9.Key? key,
    bool isOnboarding = false,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         PropertyManagerProfileRoute.name,
         args: PropertyManagerProfileRouteArgs(
           key: key,
           isOnboarding: isOnboarding,
         ),
         initialChildren: children,
       );

  static const String name = 'PropertyManagerProfileRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyManagerProfileRouteArgs>(
        orElse: () => const PropertyManagerProfileRouteArgs(),
      );
      return _i5.PropertyManagerProfileScreen(
        key: args.key,
        isOnboarding: args.isOnboarding,
      );
    },
  );
}

class PropertyManagerProfileRouteArgs {
  const PropertyManagerProfileRouteArgs({this.key, this.isOnboarding = false});

  final _i9.Key? key;

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
/// [_i6.RegisterScreen]
class RegisterRoute extends _i8.PageRouteInfo<void> {
  const RegisterRoute({List<_i8.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i6.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i7.TrialWelcomeScreen]
class TrialWelcomeRoute extends _i8.PageRouteInfo<void> {
  const TrialWelcomeRoute({List<_i8.PageRouteInfo>? children})
    : super(TrialWelcomeRoute.name, initialChildren: children);

  static const String name = 'TrialWelcomeRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i7.TrialWelcomeScreen();
    },
  );
}
