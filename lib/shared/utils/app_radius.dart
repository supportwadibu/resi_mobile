import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 100.0;

  static BorderRadius get cardRadius => BorderRadius.circular(md);
  static BorderRadius get buttonRadius => BorderRadius.circular(sm);
  static BorderRadius get inputRadius => BorderRadius.circular(sm);
  static BorderRadius get chipRadius => BorderRadius.circular(xl);
  static BorderRadius get bottomSheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(20));
  static BorderRadius get dialogRadius => BorderRadius.circular(lg);
  static BorderRadius get imageRadius => BorderRadius.circular(md);
  static BorderRadius get avatarRadius => BorderRadius.circular(full);

  static BorderRadius topOnly(double radius) => BorderRadius.vertical(
        top: Radius.circular(radius),
      );

  static BorderRadius bottomOnly(double radius) => BorderRadius.vertical(
        bottom: Radius.circular(radius),
      );

  static BorderRadius leftOnly(double radius) => BorderRadius.horizontal(
        left: Radius.circular(radius),
      );

  static BorderRadius rightOnly(double radius) => BorderRadius.horizontal(
        right: Radius.circular(radius),
      );
}
