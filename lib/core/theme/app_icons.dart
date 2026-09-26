import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icône de chaque section, miroir de `SECTION_ICONS` du backoffice : une
/// section garde le même pictogramme partout — onglet, tuile, en-tête,
/// menu de création — et d'une application à l'autre.
abstract final class AppSectionIcons {
  static const IconData home = LucideIcons.layoutDashboard;
  static const IconData bookings = LucideIcons.calendarCheck;
  static const IconData properties = LucideIcons.bedDouble;
  static const IconData residences = LucideIcons.building2;
  static const IconData clients = LucideIcons.users;
  static const IconData expenses = LucideIcons.receipt;
  static const IconData stats = LucideIcons.chartColumn;
  static const IconData reports = LucideIcons.fileText;
  static const IconData managers = LucideIcons.userCog;
  static const IconData subscription = LucideIcons.creditCard;
  static const IconData support = LucideIcons.lifeBuoy;
  static const IconData reviews = LucideIcons.messageSquare;
  static const IconData profile = LucideIcons.circleUser;
}
