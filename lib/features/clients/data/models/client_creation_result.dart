import 'package:easy_localization/easy_localization.dart';
import 'client_model.dart';

/// Résultat d'une création de fiche client.
///
/// [client] peut être nul alors que [alreadyExisted] vaut `true` : la fiche
/// existe chez le propriétaire, mais hors du périmètre du gérant qui la
/// demande. Le serveur l'accuse sans la livrer — pas même son existence par
/// recoupement, ce qu'un 403 aurait trahi, puisqu'il ne se distinguerait qu'en
/// présence d'une fiche.
class ClientCreationResult {
  const ClientCreationResult({
    required this.client,
    required this.alreadyExisted,
  });

  /// Lit la réponse de `POST /<rôle>/clients`.
  ///
  /// `already_existed` est **à la racine**, à côté de `data`, et non dedans.
  /// Son absence vaut `false` : les réponses écrites avant l'ajout du champ
  /// ne portaient que la fiche créée.
  factory ClientCreationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return ClientCreationResult(
      // Transtypé seulement si la fiche est là : `as Map` sur `null` levait
      // une TypeError, présentée au gérant comme une erreur technique.
      client: data is Map<String, dynamic> ? ClientModel.fromJson(data) : null,
      alreadyExisted: json['already_existed'] as bool? ?? false,
    );
  }

  final ClientModel? client;
  final bool alreadyExisted;

  /// Fiche existante que l'appelant n'a pas le droit de voir.
  ///
  /// Rien à créer, et rien à réutiliser : le gérant doit en référer au
  /// propriétaire. Réessayer donnerait la même réponse.
  bool get isOutOfScope => alreadyExisted && client == null;
}

/// Ce qui s'affiche quand la fiche existe hors du périmètre du gérant.
///
/// Partagé par les deux chemins qui créent une fiche — le carnet clients et la
/// saisie d'une réservation : le gérant se heurte au même mur, il doit lire la
/// même chose. Il ne dit **pas** de réessayer, la réponse serait identique, et
/// ne nomme pas le client : la règle ferme précisément cet oracle.
String get clientOutOfScopeMessage => 'clients.out_of_scope'.tr();
