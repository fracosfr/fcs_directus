import '../core/directus_http_client.dart';

/// Modèle pour la réponse d'authentification
class AuthResponse {
  final String accessToken;
  final int expiresIn;
  final String? refreshToken;

  AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires'] as int,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}

/// Service d'authentification pour Directus.
///
/// Gère la connexion, déconnexion et rafraîchissement des tokens.
class AuthService {
  final DirectusHttpClient _httpClient;

  AuthService(this._httpClient);

  /// Connexion avec email et mot de passe
  ///
  /// [email] Email de l'utilisateur
  /// [password] Mot de passe de l'utilisateur
  /// [otp] Code OTP (optionnel)
  ///
  /// Retourne une [AuthResponse] avec les tokens
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? otp,
  }) async {
    final response = await _httpClient.post(
      '/auth/login',
      data: {'email': email, 'password': password, if (otp != null) 'otp': otp},
    );

    final authResponse = AuthResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );

    // Stocker les tokens dans le client HTTP
    _httpClient.setTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    return authResponse;
  }

  /// Connexion avec un token statique
  ///
  /// [token] Token statique généré depuis Directus
  Future<void> loginWithToken(String token) async {
    _httpClient.setTokens(accessToken: token);
  }

  /// Rafraîchit le token d'accès
  ///
  /// [refreshToken] Token de rafraîchissement (optionnel, utilise celui stocké si non fourni)
  ///
  /// Retourne une nouvelle [AuthResponse]
  Future<AuthResponse> refresh({String? refreshToken}) async {
    final token = refreshToken ?? _httpClient.refreshToken;

    if (token == null) {
      throw Exception('Aucun refresh token disponible');
    }

    final response = await _httpClient.post(
      '/auth/refresh',
      data: {'refresh_token': token},
    );

    final authResponse = AuthResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );

    // Mettre à jour les tokens
    _httpClient.setTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken ?? token,
    );

    return authResponse;
  }

  /// Déconnexion
  ///
  /// Invalide le refresh token sur le serveur
  Future<void> logout() async {
    final refreshToken = _httpClient.refreshToken;

    if (refreshToken != null) {
      try {
        await _httpClient.post(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      } catch (e) {
        // Ignorer les erreurs de déconnexion
      }
    }

    // Supprimer les tokens localement
    _httpClient.setTokens();
  }

  /// Demande de réinitialisation de mot de passe
  ///
  /// [email] Email de l'utilisateur
  Future<void> requestPasswordReset(String email) async {
    await _httpClient.post('/auth/password/request', data: {'email': email});
  }

  /// Réinitialisation du mot de passe
  ///
  /// [token] Token reçu par email
  /// [password] Nouveau mot de passe
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _httpClient.post(
      '/auth/password/reset',
      data: {'token': token, 'password': password},
    );
  }

  /// Vérifie si l'utilisateur est authentifié
  bool get isAuthenticated => _httpClient.accessToken != null;

  /// Récupère le token d'accès actuel
  String? get accessToken => _httpClient.accessToken;
}
