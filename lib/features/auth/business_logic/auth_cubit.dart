import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../data/services/auth_service.dart';
import '../data/services/google_auth_service.dart';
import '../data/services/property_manager_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service;
  final PropertyManagerService _propertyManagerService;

  AuthCubit(
    this._service,
    this._propertyManagerService,
  ) : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final auth = await _service.login(email, password);
      if (!isClosed) emit(AuthSuccess(auth));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }

  /// Démarre l'inscription. Émet [AuthOtpSent] — et non [AuthSuccess] : le
  /// compte existe mais n'est pas vérifié, aucun token n'a été délivré.
  /// L'UI doit enchaîner sur la saisie du code, puis appeler [verifyRegistration].
  Future<void> register({
    required String fullName,
    required String password,
    required String authChannel,
    String? email,
    String? phone,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _service.initRegistration(
        fullName: fullName,
        password: password,
        authChannel: authChannel,
        email: email,
        phone: phone,
      );
      if (!isClosed) {
        emit(
          AuthOtpSent(
            channel: authChannel,
            target: result.target,
            devOtpCode: result.devOtpCode,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }

  /// Finalise l'inscription avec le code reçu et ouvre la session.
  Future<void> verifyRegistration({
    required String channel,
    required String target,
    required String code,
  }) async {
    emit(const AuthLoading());
    try {
      final auth = await _service.verifyRegistration(
        channel: channel,
        target: target,
        code: code,
      );
      if (!isClosed) emit(AuthSuccess(auth));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }

  /// Connexion Google : le service obtient l'ID token puis l'échange contre
  /// les tokens de l'API. L'annulation par l'utilisateur n'est pas une erreur.
  Future<void> loginWithGoogle() async {
    emit(const AuthLoading());
    try {
      final auth = await _service.loginWithGoogle();
      if (!isClosed) emit(AuthSuccess(auth));
    } on GoogleSignInCancelled {
      if (!isClosed) emit(const AuthCancelled());
    } on GoogleSignInFailure catch (f) {
      if (!isClosed) emit(AuthError(f.message));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }

  /// Le dossier de validation a-t-il été déposé ?
  ///
  /// Consulté après l'ouverture de session pour décider si l'utilisateur doit
  /// être conduit vers l'écran de finalisation. `null` signale un état
  /// indéterminable — hors ligne, session expirée — que l'appelant tranche
  /// selon ce que coûte son erreur.
  Future<bool?> isProfileSubmitted() {
    return _propertyManagerService.isProfileSubmitted();
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      // `AuthService.logout` révoque la session serveur, purge le stockage
      // sécurisé et déconnecte Google.
      await _service.logout();
      await _propertyManagerService.clearPropertyManager();
      if (!isClosed) emit(const AuthLoggedOut());
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }
}
