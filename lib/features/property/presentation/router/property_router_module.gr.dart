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
import 'package:resi_africa/features/property/data/models/property_model.dart'
    as _i7;
import 'package:resi_africa/features/property/presentation/screens/add_property_screen.dart'
    as _i1;
import 'package:resi_africa/features/property/presentation/screens/property_detail_screen.dart'
    as _i2;
import 'package:resi_africa/features/property/presentation/screens/property_screen.dart'
    as _i3;
import 'package:resi_africa/features/property/presentation/screens/success_screen.dart'
    as _i4;

/// generated route for
/// [_i1.AddPropertyScreen]
class AddPropertyRoute extends _i5.PageRouteInfo<void> {
  const AddPropertyRoute({List<_i5.PageRouteInfo>? children})
    : super(AddPropertyRoute.name, initialChildren: children);

  static const String name = 'AddPropertyRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddPropertyScreen();
    },
  );
}

/// generated route for
/// [_i2.PropertyDetailScreen]
class PropertyDetailRoute extends _i5.PageRouteInfo<PropertyDetailRouteArgs> {
  PropertyDetailRoute({
    _i6.Key? key,
    required _i7.PropertyModel property,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         PropertyDetailRoute.name,
         args: PropertyDetailRouteArgs(key: key, property: property),
         initialChildren: children,
       );

  static const String name = 'PropertyDetailRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyDetailRouteArgs>();
      return _i2.PropertyDetailScreen(key: args.key, property: args.property);
    },
  );
}

class PropertyDetailRouteArgs {
  const PropertyDetailRouteArgs({this.key, required this.property});

  final _i6.Key? key;

  final _i7.PropertyModel property;

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
/// [_i3.PropertyScreen]
class PropertyRoute extends _i5.PageRouteInfo<void> {
  const PropertyRoute({List<_i5.PageRouteInfo>? children})
    : super(PropertyRoute.name, initialChildren: children);

  static const String name = 'PropertyRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i3.PropertyScreen();
    },
  );
}

/// generated route for
/// [_i4.SuccessScreen]
class SuccessRoute extends _i5.PageRouteInfo<SuccessRouteArgs> {
  SuccessRoute({
    _i6.Key? key,
    String title = 'Félicitations !',
    String subtitle = 'Votre bien a été enregistré avec succès',
    String buttonText = 'Voir mes biens',
    String secondaryButtonText = 'Ajouter un autre bien',
    int autoRedirectDuration = 5,
    _i6.VoidCallback? onPrimaryAction,
    _i6.VoidCallback? onSecondaryAction,
    List<_i5.PageRouteInfo>? children,
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

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SuccessRouteArgs>(
        orElse: () => const SuccessRouteArgs(),
      );
      return _i4.SuccessScreen(
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

  final _i6.Key? key;

  final String title;

  final String subtitle;

  final String buttonText;

  final String secondaryButtonText;

  final int autoRedirectDuration;

  final _i6.VoidCallback? onPrimaryAction;

  final _i6.VoidCallback? onSecondaryAction;

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
