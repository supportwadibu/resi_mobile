import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/property_manager_model.dart';

/// Levée quand l'utilisateur ferme la feuille Google sans choisir de compte.
/// Ce n'est pas une erreur : l'UI ne doit pas afficher de message d'échec.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Levée quand Google ne fournit pas d'ID token exploitable.
class GoogleSignInFailure implements Exception {
  const GoogleSignInFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Encapsule le SDK Google Sign-In.
///
/// Son unique rôle est d'obtenir un **ID token** — un JWT signé par Google que
/// le backend peut vérifier hors ligne. On n'utilise pas l'`accessToken` : il
/// ne prouve pas l'identité et n'est pas vérifiable sans appel réseau.
/// L'authentification applicative reste la responsabilité de l'API.
class GoogleAuthService {
  GoogleAuthService(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  /// Ouvre le sélecteur de compte Google et retourne l'ID token obtenu.
  ///
  /// Throws [GoogleSignInCancelled] si l'utilisateur annule,
  /// [GoogleSignInFailure] si aucun ID token n'est retourné.
  Future<String> obtainIdToken() async {
    // Repart d'un état propre : sans cela, le SDK reconnecte silencieusement
    // le dernier compte et l'utilisateur ne peut plus en changer.
    await _googleSignIn.signOut();

    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // Le SDK natif remonte ses échecs sous forme de PlatformException. Sans
      // ce catch, l'exception traverse le cubit et l'utilisateur reste devant
      // un écran figé, sans le moindre message.
      throw GoogleSignInFailure(_messageForPlatformError(e));
    }

    if (account == null) {
      throw const GoogleSignInCancelled();
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      // Sur Android, un idToken nul signifie presque toujours que
      // `serverClientId` (client OAuth de type Web) n'est pas configuré.
      throw const GoogleSignInFailure(
        "Google n'a pas fourni de jeton d'identité. Vérifiez la configuration OAuth.",
      );
    }

    return idToken;
  }

  /// Traduit un échec du SDK natif en message lisible.
  ///
  /// Les codes viennent de `com.google.android.gms.common.api.ApiException` :
  /// bruts, ils n'apprennent rien à l'utilisateur et rendent le diagnostic
  /// pénible côté développement.
  static String _messageForPlatformError(PlatformException e) {
    final String details = '${e.message ?? ''} ${e.details ?? ''}';

    // 10 = DEVELOPER_ERROR : Play Services ne reconnaît pas la signature de
    // l'APK. Il manque le client OAuth Android correspondant au couple
    // (nom du package, empreinte SHA-1) dans la console Google Cloud.
    if (details.contains('ApiException: 10')) {
      return "La connexion Google n'est pas configurée pour cette version de "
          "l'application. Contactez le support.";
    }

    // 7 = NETWORK_ERROR
    if (details.contains('ApiException: 7')) {
      return 'Connexion impossible. Vérifiez votre accès à Internet.';
    }

    // 12500 : Play Services absent, obsolète, ou compte Google indisponible.
    if (details.contains('12500')) {
      return 'Google Play Services est indisponible ou doit être mis à jour.';
    }

    return "La connexion Google a échoué. Réessayez dans un instant.";
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<GoogleSignInAccount?> getCurrentUser() => _googleSignIn.signInSilently();

  PropertyManagerModel createPropertyManagerFromGoogle(
    GoogleSignInAccount googleUser,
    String phoneNumber,
  ) {
    return PropertyManagerModel(
      id: googleUser.id,
      email: googleUser.email,
      name: googleUser.displayName ?? '',
      phoneNumber: phoneNumber,
      photoUrl: googleUser.photoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
