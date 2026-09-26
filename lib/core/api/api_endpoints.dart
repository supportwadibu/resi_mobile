import 'api_paths.dart';

abstract final class ApiEndpoints {
  static const String _v1 = '/api/v1';

  static const String login = '$_v1/auth/login';
  static const String register = '$_v1/auth/register';

  static const String registerInit = '$_v1/auth/register/init';
  static const String registerVerify = '$_v1/auth/register/verify';

  static const String googleLogin = '$_v1/auth/google';
  static const String refresh = '$_v1/auth/refresh';
  static const String logout = '$_v1/auth/logout';
  static const String me = '$_v1/auth/me';

  /// État d'abonnement du propriétaire connecté (essai, jours restants,
  /// statut du dossier de validation).
  static const String proprioSubscription = '$_v1/proprio/subscription';

  /// Forfaits proposés à la souscription, du moins cher au plus cher.
  static const String proprioPlans = '$_v1/proprio/plans';

  /// Lance le paiement Wave d'un forfait ; renvoie le lien de paiement.
  static const String proprioSubscriptionCheckout =
      '$_v1/proprio/subscription/checkout';

  /// Constate l'issue d'un paiement au retour de Wave, sans attendre le
  /// webhook : le serveur relit la session chez Wave.
  static String proprioSubscriptionConfirm(String reference) =>
      '$_v1/proprio/subscription/checkout/$reference/confirm';

  /// Dossier de validation : coordonnées et pièces d'identité déposées à la
  /// suite de l'inscription. `GET` pour relire, `POST` (multipart) pour déposer.
  static const String proprioProfile = '$_v1/proprio/profile';

  /// Compte du gérant connecté. `GET` pour relire, `PATCH` pour changer son nom
  /// ou son mot de passe.
  ///
  /// Chemin fixe et non dérivé du rôle, contrairement aux listes : la route
  /// rend un `ManagerDto` — nom, coordonnées, périmètre, état du compte —,
  /// d'une forme sans rapport avec le dossier de validation servi par
  /// `proprioProfile`. Les réunir derrière un `profile(role)` laisserait croire
  /// à deux variantes d'une même ressource, et un modèle unique lirait à vide
  /// les champs que l'autre ne porte pas.
  static const String gerantProfile = '$_v1/gerant/profile';

  static const String homes = '/homes';

  /// Annonces servies par l'appelant — son parc entier pour le propriétaire,
  /// ses seuls logements affectés pour le gérant.
  /// `GET` pour lister, `POST` pour créer.
  static String properties(String role) =>
      '${basePathForRole(role)}/properties';

  /// État instantané du parc : nombre d'unités au total, publiées, louées,
  /// en brouillon. Sans bornes de période, contrairement au relevé financier.
  static const String proprioPropertyStats = '$_v1/proprio/properties/stats';

  /// Dépôt des photos d'annonce, qui retourne leurs URLs publiques.
  ///
  /// Séparé de la création : le secret Cloudinary ne quittant pas le serveur,
  /// l'upload direct depuis le mobile est exclu.
  static const String proprioPropertyImages = '$_v1/proprio/properties/images';

  /// Résidences de l'appelant : des lieux regroupant plusieurs logements.
  /// `GET` pour lister, `POST` pour créer.
  static String residences(String role) =>
      '${basePathForRole(role)}/residences';

  static String residence(String role, String id) =>
      '${basePathForRole(role)}/residences/$id';

  /// Rattache un bien à une résidence, ou l’en détache avec
  /// `residence_id: null`.
  ///
  /// Route dédiée et non un champ du PATCH générique : le rattachement
  /// déplace un compteur sur deux résidences et peut recopier l’adresse.
  static String propertyResidence(String role, String id) =>
      '${basePathForRole(role)}/properties/$id/residence';

  static String property(String role, String id) =>
      '${basePathForRole(role)}/properties/$id';

  /// Mise en ligne d'une annonce, et retrait de la vitrine.
  ///
  /// Deux routes dédiées plutôt qu'un champ de `PATCH :id` : la publication
  /// exige un dossier d'identité déposé et horodate la mise en ligne.
  static String proprioPropertyPublish(String id) =>
      '$_v1/proprio/properties/$id/publish';

  static String proprioPropertyUnpublish(String id) =>
      '$_v1/proprio/properties/$id/unpublish';

  /// Périodes déjà réservées sur un bien, pour barrer les dates au calendrier
  /// de saisie plutôt que d'essuyer un refus après coup.
  static String propertyAvailability(String role) =>
      '${basePathForRole(role)}/properties/availability';

  /// Réservations servies par l'appelant — son parc entier pour le
  /// propriétaire, ses seuls logements affectés pour le gérant.
  /// `GET` pour lister, `POST` pour enregistrer une réservation au comptoir.
  static String bookings(String role) => '${basePathForRole(role)}/bookings';

  static String booking(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id';

  /// Chiffres du tableau de bord des réservations : taux d'occupation du mois,
  /// séjours à venir et en cours, revenu du mois rapporté au précédent.
  ///
  /// Sans paramètre de période, contrairement au relevé financier : l'écran
  /// montre le mois en cours, et laisser le cadrage au client ferait diverger
  /// les compteurs et le bloc revenus affichés côte à côte.
  ///
  /// Le serveur cloisonne ces compteurs sur les logements de l'appelant, taux
  /// d'occupation compris : le gérant en lit les siens, et non ceux du parc.
  /// Le chemin propriétaire écrit en dur rendait ici un 403 au gérant, qui
  /// perdait des compteurs auxquels il a droit.
  static String bookingStats(String role) =>
      '${basePathForRole(role)}/bookings/stats';

  /// Clôture d'un séjour, mené à terme ou écourté par un départ anticipé.
  static String bookingCheckOut(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id/check-out';

  /// Chiffrage d'un départ anticipé, sans écriture : jours facturés, prorata
  /// proposé et remboursement.
  static String bookingCheckOutPreview(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id/check-out/preview';

  /// Prolongation d’un séjour comptoir : repousse la sortie et réajuste le
  /// montant. Un 409 est un conflit de période à arbitrer, pas une panne.
  static String bookingExtend(String role, String id) =>
      '${basePathForRole(role)}/bookings/$id/extend';

  /// Carnet de clients de l'appelant — des clients qui se présentent au
  /// comptoir et n'ont pas de compte sur la plateforme.
  /// `GET` pour lister et rechercher, `POST` (multipart) pour enregistrer.
  static String clients(String role) => '${basePathForRole(role)}/clients';

  /// Recherche d'une fiche par numéro, appelée pendant la saisie : le
  /// téléphone identifie le client, et proposer la fiche existante évite un
  /// doublon dans le carnet.
  static String clientLookup(String role) =>
      '${basePathForRole(role)}/clients/lookup';

  static String client(String role, String id) =>
      '${basePathForRole(role)}/clients/$id';

  /// Historique des séjours d'un client, statistiques recalculées comprises.
  ///
  /// Les cumuls sont servis ici plutôt que lus sur la fiche : ils dérivent des
  /// mêmes réservations, et les demander à part exposerait à afficher un total
  /// qui contredit la liste juste en dessous.
  static String clientBookings(String role, String id) =>
      '${basePathForRole(role)}/clients/$id/bookings';

  /// Dépenses de l'appelant. `GET` pour lister, `POST` pour créer.
  static String expenses(String role) => '${basePathForRole(role)}/expenses';

  /// Total et ventilation par catégorie, filtrés comme la liste.
  static String expenseSummary(String role) =>
      '${basePathForRole(role)}/expenses/summary';

  static String expense(String role, String id) =>
      '${basePathForRole(role)}/expenses/$id';

  /// Revenus, charges et bénéfice net de l'appelant.
  static String financeOverview(String role) =>
      '${basePathForRole(role)}/finance/overview';

  /// Avis et suggestions sur l'application, adressés à l'équipe RESI.
  /// `GET` pour relire les siens, `POST` pour en envoyer un.
  ///
  /// Sans rapport avec les avis portant sur un bien : ici le propriétaire parle
  /// du produit, et le lecteur est l'équipe qui le développe.
  static const String proprioFeedbacks = '$_v1/proprio/feedbacks';

  /// Génération d'un rapport PDF (financier, performance, réservations).
  ///
  /// La réponse porte une URL signée à durée limitée (15 minutes) vers le
  /// fichier généré, jamais le fichier lui-même : rien à mettre en cache ici.
  static const String reports = '$_v1/proprio/reports';

  /// Gérants du propriétaire connecté : comptes et périmètres.
  static const String proprioManagers = '$_v1/proprio/managers';

  static String proprioManager(String id) => '$_v1/proprio/managers/$id';

  /// Remplacement du périmètre — `PUT`, la liste complète des logements
  /// affectés : un ajout et un retrait faits ensemble deviennent une seule
  /// écriture, et l'état obtenu ne dépend pas de l'ordre des requêtes.
  static String proprioManagerProperties(String id) =>
      '$_v1/proprio/managers/$id/properties';

  static String proprioManagerStatus(String id) =>
      '$_v1/proprio/managers/$id/status';
}
