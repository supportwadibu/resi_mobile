import '../models/client_model.dart';
import 'id_label_parser.dart';
import 'mrz_parser.dart';

/// Tout ce qu'une photo de pièce a permis de lire, champ par champ.
///
/// Chaque champ est facultatif : la lecture préremplit, elle ne décide pas. Un
/// champ `null` reste à saisir, maintenant ou plus tard depuis la fiche.
class IdCardReading {
  const IdCardReading({
    this.documentType,
    this.documentNumber,
    this.fullName,
    this.birthDate,
    this.birthPlace,
    this.nationality,
    this.address,
    this.issuedAt,
  });

  final ClientIdDocumentType? documentType;
  final String? documentNumber;

  /// Prénoms puis nom, l'ordre d'usage au carnet.
  final String? fullName;
  final DateTime? birthDate;
  final String? birthPlace;
  final String? nationality;
  final String? address;
  final DateTime? issuedAt;

  /// Combine les deux lectures d'un même texte.
  ///
  /// La MRZ prime sur tout ce qu'elle porte : ses champs sont vérifiés par
  /// chiffres de contrôle, là où les libellés sont lus au jugé. Les libellés
  /// complètent ce qu'elle n'a pas — lieu de naissance, délivrance, domicile.
  ///
  /// `null` si rien n'a été lu.
  static IdCardReading? fromText(String text) {
    final mrz = MrzParser.parse(text);
    final labels = IdLabelParser.parse(text);
    if (mrz == null && labels.isEmpty) return null;

    final labelName = [labels.givenNames, labels.surname]
        .whereType<String>()
        .join(' ');

    return IdCardReading(
      documentType: mrz?.documentType,
      documentNumber: mrz?.documentNumber ?? labels.documentNumber,
      fullName: mrz?.fullName ?? (labelName.isEmpty ? null : labelName),
      birthDate: mrz?.birthDate ?? labels.birthDate,
      birthPlace: labels.birthPlace,
      nationality: nationalityLabel(mrz?.nationality) ?? labels.nationality,
      address: labels.address,
      issuedAt: labels.issuedAt,
    );
  }

  bool get isEmpty =>
      documentType == null &&
      documentNumber == null &&
      fullName == null &&
      birthDate == null &&
      birthPlace == null &&
      nationality == null &&
      address == null &&
      issuedAt == null;

  /// Complète cette lecture par une autre, sans rien écraser : la première
  /// face lue fait foi, la seconde comble ses trous.
  IdCardReading merge(IdCardReading other) {
    return IdCardReading(
      documentType: documentType ?? other.documentType,
      documentNumber: documentNumber ?? other.documentNumber,
      fullName: fullName ?? other.fullName,
      birthDate: birthDate ?? other.birthDate,
      birthPlace: birthPlace ?? other.birthPlace,
      nationality: nationality ?? other.nationality,
      address: address ?? other.address,
      issuedAt: issuedAt ?? other.issuedAt,
    );
  }

  /// Code pays ICAO de la MRZ → nationalité telle que le registre l'écrit.
  ///
  /// Les pays d'où viennent la plupart des clients d'une résidence ivoirienne.
  /// Un code absent de la table est rendu tel quel : « GHA » reste lisible
  /// et se corrige à la main, un champ vide se remarquerait moins.
  static String? nationalityLabel(String? code) {
    if (code == null) return null;
    return _nationalities[code] ?? code;
  }

  static const _nationalities = {
    'CIV': 'Ivoirienne',
    'BFA': 'Burkinabè',
    'MLI': 'Malienne',
    'SEN': 'Sénégalaise',
    'GIN': 'Guinéenne',
    'GHA': 'Ghanéenne',
    'TGO': 'Togolaise',
    'BEN': 'Béninoise',
    'NER': 'Nigérienne',
    'NGA': 'Nigériane',
    'LBR': 'Libérienne',
    'SLE': 'Sierra-léonaise',
    'CMR': 'Camerounaise',
    'GAB': 'Gabonaise',
    'COG': 'Congolaise',
    'COD': 'Congolaise (RDC)',
    'MRT': 'Mauritanienne',
    'MAR': 'Marocaine',
    'TUN': 'Tunisienne',
    'LBN': 'Libanaise',
    'FRA': 'Française',
    'BEL': 'Belge',
    'CHE': 'Suisse',
    'D': 'Allemande',
    'GBR': 'Britannique',
    'USA': 'Américaine',
    'CAN': 'Canadienne',
    'CHN': 'Chinoise',
    'IND': 'Indienne',
  };
}
