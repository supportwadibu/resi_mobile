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

  /// Dossier de validation : coordonnées et pièces d'identité déposées à la
  /// suite de l'inscription. `GET` pour relire, `POST` (multipart) pour déposer.
  static const String proprioProfile = '$_v1/proprio/profile';

  static const String homes = '/homes';

  /// Annonces du propriétaire connecté. `GET` pour lister, `POST` pour créer.
  static const String proprioProperties = '$_v1/proprio/properties';

  /// Dépôt des photos d'annonce, qui retourne leurs URLs publiques.
  ///
  /// Séparé de la création : le secret Cloudinary ne quittant pas le serveur,
  /// l'upload direct depuis le mobile est exclu.
  static const String proprioPropertyImages = '$_v1/proprio/properties/images';

  static String proprioProperty(String id) => '$_v1/proprio/properties/$id';

  /// Périodes déjà réservées sur un bien, pour barrer les dates au calendrier
  /// de saisie plutôt que d'essuyer un refus après coup.
  static const String proprioPropertyAvailability =
      '$_v1/proprio/properties/availability';

  /// Réservations reçues sur les biens du propriétaire connecté.
  /// `GET` pour lister, `POST` pour enregistrer une réservation au comptoir.
  static const String proprioBookings = '$_v1/proprio/bookings';

  /// Clôture d'un séjour : enregistre la sortie et cumule le montant sur la
  /// fiche du client.
  static String proprioBookingCheckOut(String id) =>
      '$_v1/proprio/bookings/$id/check-out';

  /// Carnet de clients du propriétaire connecté — des clients qui se
  /// présentent au comptoir et n'ont pas de compte sur la plateforme.
  /// `GET` pour lister et rechercher, `POST` (multipart) pour enregistrer.
  static const String proprioClients = '$_v1/proprio/clients';

  /// Recherche d'une fiche par numéro, appelée pendant la saisie : le
  /// téléphone identifie le client, et proposer la fiche existante évite un
  /// doublon dans le carnet.
  static const String proprioClientLookup = '$_v1/proprio/clients/lookup';

  static String proprioClient(String id) => '$_v1/proprio/clients/$id';

  static const String reservations = '/reservations';

  /// Dépenses du propriétaire connecté. `GET` pour lister, `POST` pour créer.
  static const String proprioExpenses = '$_v1/proprio/expenses';

  /// Total et ventilation par catégorie, filtrés comme la liste.
  static const String proprioExpenseSummary = '$_v1/proprio/expenses/summary';

  static String proprioExpense(String id) => '$_v1/proprio/expenses/$id';

  /// Revenus, charges et bénéfice net du propriétaire connecté.
  static const String proprioFinanceOverview =
      '$_v1/proprio/finance/overview';

  static const String stats = "/stats";
  static const String rapports = "/rapports";
  static const String clients = "/clients";
}
