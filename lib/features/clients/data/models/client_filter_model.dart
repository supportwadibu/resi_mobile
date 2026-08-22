enum ClientFilter { all, active, archived }

extension ClientFilterExt on ClientFilter {
  String get label {
    switch (this) {
      case ClientFilter.all:
        return 'Tous';
      case ClientFilter.active:
        return 'Actifs';
      case ClientFilter.archived:
        return 'Archivés';
    }
  }
}
