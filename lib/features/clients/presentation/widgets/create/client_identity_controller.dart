import 'package:flutter/widgets.dart';

import '../../../data/models/client_model.dart';
import '../../../data/services/id_card_reading.dart';

/// Pièce et identité d'une fiche en cours de saisie, préremplissables par la
/// lecture de la pièce.
///
/// Partagé par la création et la modification d'une fiche : les mêmes champs,
/// la même règle de préremplissage. Les zones de texte gardent leurs propres
/// contrôleurs ; les dates et la nature de la pièce, qui n'en ont pas, sont
/// portées ici et notifiées.
class ClientIdentityController extends ChangeNotifier {
  ClientIdentityController({
    ClientIdDocumentType? documentType,
    String? documentNumber,
    ClientIdentity identity = ClientIdentity.empty,
  }) : _documentType = documentType,
       _birthDate = identity.birthDate,
       _issuedAt = identity.idDocumentIssuedAt,
       documentNumber = TextEditingController(text: documentNumber ?? ''),
       birthPlace = TextEditingController(text: identity.birthPlace ?? ''),
       nationality = TextEditingController(text: identity.nationality ?? ''),
       address = TextEditingController(text: identity.address ?? '');

  final TextEditingController documentNumber;
  final TextEditingController birthPlace;
  final TextEditingController nationality;
  final TextEditingController address;

  ClientIdDocumentType? _documentType;
  DateTime? _birthDate;
  DateTime? _issuedAt;

  ClientIdDocumentType? get documentType => _documentType;
  DateTime? get birthDate => _birthDate;
  DateTime? get issuedAt => _issuedAt;

  set documentType(ClientIdDocumentType? value) {
    _documentType = value;
    notifyListeners();
  }

  set birthDate(DateTime? value) {
    _birthDate = value;
    notifyListeners();
  }

  set issuedAt(DateTime? value) {
    _issuedAt = value;
    notifyListeners();
  }

  /// Numéro saisi, `null` si vide.
  String? get documentNumberValue {
    final value = documentNumber.text.trim();
    return value.isEmpty ? null : value;
  }

  ClientIdentity get identity => ClientIdentity(
    birthDate: _birthDate,
    birthPlace: _textOrNull(birthPlace),
    nationality: _textOrNull(nationality),
    address: _textOrNull(address),
    idDocumentIssuedAt: _issuedAt,
  );

  /// Reporte une lecture de la pièce dans les champs.
  ///
  /// [overwrite] : le propriétaire vient de scanner la pièce du client
  /// présent, c'est la source la plus sûre qu'il ait — ce qui est lu remplace
  /// la saisie. Sans lui — une photo déposée dans une case recto ou verso —,
  /// la lecture ne comble que les champs vides : elle ne défait pas une
  /// correction faite à la main.
  ///
  /// Un champ que la lecture n'a pas trouvé n'est jamais vidé.
  void apply(IdCardReading reading, {required bool overwrite}) {
    bool take(Object? current) =>
        overwrite || current == null || (current is String && current.isEmpty);

    if (reading.documentType != null && take(_documentType)) {
      _documentType = reading.documentType;
    }
    if (reading.birthDate != null && take(_birthDate)) {
      _birthDate = reading.birthDate;
    }
    if (reading.issuedAt != null && take(_issuedAt)) {
      _issuedAt = reading.issuedAt;
    }
    _fill(documentNumber, reading.documentNumber, take);
    _fill(birthPlace, reading.birthPlace, take);
    _fill(nationality, reading.nationality, take);
    _fill(address, reading.address, take);

    notifyListeners();
  }

  static void _fill(
    TextEditingController field,
    String? value,
    bool Function(Object?) take,
  ) {
    if (value == null || !take(field.text.trim())) return;
    field.text = value;
  }

  static String? _textOrNull(TextEditingController field) {
    final value = field.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    documentNumber.dispose();
    birthPlace.dispose();
    nationality.dispose();
    address.dispose();
    super.dispose();
  }
}
