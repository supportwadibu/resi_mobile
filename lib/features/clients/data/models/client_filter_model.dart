import 'package:easy_localization/easy_localization.dart';
enum ClientFilter { all, active, archived }

extension ClientFilterExt on ClientFilter {
  String get label {
    switch (this) {
      case ClientFilter.all:
        return 'client_filter.all'.tr();
      case ClientFilter.active:
        return 'client_filter.active'.tr();
      case ClientFilter.archived:
        return 'client_filter.archived'.tr();
    }
  }
}
