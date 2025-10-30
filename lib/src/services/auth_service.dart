import '../core/directus_http_client.dart';

/// Mode d'authentification pour les réponses Directus.
///
/// Détermine si les tokens sont retournés en JSON ou stockés dans un cookie httpOnly.
enum AuthMode {
  /// Retourne les tokens dans la réponse JSON (par défaut).
  json,

  /// Stocke le refresh token dans un cookie httpOnly et retourne l'access token.
  cookie,

  /// Stocke les deux tokens dans des cookies httpOnly.
  session;

  /// Convertit l'enum en valeur pour l'API Directus.
  String toApiValue() {
    switch (this) {
      case AuthMode.json:
        return 'json';
      case AuthMode.cookie:
        return 'cookie';
      case AuthMode.session:
        return 'session';
    }
  }
}

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

/// Fournisseur OAuth disponible sur le serveur Directus.
class OAuthProvider {
  /// Nom du fournisseur (ex: 'google', 'github', 'facebook').
  final String name;

  /// Icône du fournisseur (SVG ou URL).
  final String? icon;

  OAuthProvider({required this.name, this.icon});

  factory OAuthProvider.fromJson(Map<String, dynamic> json) {
    return OAuthProvider(
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (icon != null) 'icon': icon,
  };
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
  /// [otp] Code OTP (optionnel) pour l'authentification à deux facteurs
  /// [mode] Mode d'authentification (json, cookie, ou session). Par défaut: json
  ///
  /// Retourne une [AuthResponse] avec les tokens (sauf si mode=session)
  ///
  /// ```dart
  /// // Authentification classique
  /// final response = await client.auth.login(
  ///   email: 'user@example.com',
  ///   password: 'password',
  /// );
  ///
  /// // Avec OTP (Two-Factor Authentication)
  /// final response = await client.auth.login(
  ///   email: 'user@example.com',
  ///   password: 'password',
  ///   otp: '123456',
  /// );
  ///
  /// // Mode cookie (refresh token dans un httpOnly cookie)
  /// await client.auth.login(
  ///   email: 'user@example.com',
  ///   password: 'password',
  ///   mode: AuthMode.cookie,
  /// );
  /// ```
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? otp,
    AuthMode mode = AuthMode.json,
  }) async {
    final response = await _httpClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        if (otp != null) 'otp': otp,
        'mode': mode.toApiValue(),
      },
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
  /// [mode] Mode d'authentification (json, cookie, ou session). Par défaut: json
  ///
  /// Retourne une nouvelle [AuthResponse]
  ///
  /// ```dart
  /// // Rafraîchissement automatique (utilise le token stocké)
  /// final response = await client.auth.refresh();
  ///
  /// // Avec un token spécifique
  /// final response = await client.auth.refresh(
  ///   refreshToken: 'my-refresh-token',
  /// );
  ///
  /// // Mode cookie
  /// await client.auth.refresh(mode: AuthMode.cookie);
  /// ```
  Future<AuthResponse> refresh({
    String? refreshToken,
    AuthMode mode = AuthMode.json,
  }) async {
    final token = refreshToken ?? _httpClient.refreshToken;

    if (token == null) {
      throw Exception('Aucun refresh token disponible');
    }

    final response = await _httpClient.post(
      '/auth/refresh',
      data: {'refresh_token': token, 'mode': mode.toApiValue()},
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
  ///
  /// [mode] Mode d'authentification (json, cookie, ou session). Par défaut: json
  ///
  /// ```dart
  /// // Déconnexion classique
  /// await client.auth.logout();
  ///
  /// // Avec mode cookie (pour effacer les cookies httpOnly)
  /// await client.auth.logout(mode: AuthMode.cookie);
  /// ```
  Future<void> logout({AuthMode mode = AuthMode.json}) async {
    final refreshToken = _httpClient.refreshToken;

    if (refreshToken != null) {
      try {
        await _httpClient.post(
          '/auth/logout',
          data: {'refresh_token': refreshToken, 'mode': mode.toApiValue()},
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
  /// [resetUrl] URL personnalisée pour le lien de réinitialisation (optionnel)
  ///
  /// L'URL de réinitialisation doit être dans la liste autorisée
  /// (PASSWORD_RESET_URL_ALLOW_LIST dans la configuration Directus).
  ///
  /// ```dart
  /// // Réinitialisation standard
  /// await client.auth.requestPasswordReset('user@example.com');
  ///
  /// // Avec URL personnalisée
  /// await client.auth.requestPasswordReset(
  ///   'user@example.com',
  ///   resetUrl: 'https://myapp.com/reset-password',
  /// );
  /// ```
  Future<void> requestPasswordReset(String email, {String? resetUrl}) async {
    await _httpClient.post(
      '/auth/password/request',
      data: {'email': email, if (resetUrl != null) 'reset_url': resetUrl},
    );
  }

  /// Réinitialisation du mot de passe
  ///
  /// [token] Token reçu par email
  /// [password] Nouveau mot de passe
  ///
  /// ```dart
  /// await client.auth.resetPassword(
  ///   token: 'token-from-email',
  ///   password: 'new-secure-password',
  /// );
  /// ```
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _httpClient.post(
      '/auth/password/reset',
      data: {'token': token, 'password': password},
    );
  }

  /// Liste tous les fournisseurs OAuth disponibles
  ///
  /// Retourne la liste des providers OAuth configurés sur le serveur Directus
  /// (ex: Google, GitHub, Facebook, etc.)
  ///
  /// ```dart
  /// final providers = await client.auth.listOAuthProviders();
  /// for (var provider in providers) {
  ///   print('Provider: ${provider.name}');
  /// }
  /// ```
  Future<List<OAuthProvider>> listOAuthProviders() async {
    final response = await _httpClient.get('/auth/oauth');

    final data = response.data['data'] as List;
    return data
        .map((json) => OAuthProvider.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Génère l'URL de connexion OAuth pour un fournisseur
  ///
  /// [provider] Nom du fournisseur OAuth (ex: 'google', 'github', 'facebook')
  /// [redirect] URL de redirection après authentification (optionnel)
  ///
  /// Retourne l'URL complète vers laquelle rediriger l'utilisateur pour
  /// initier le flow OAuth.
  ///
  /// ```dart
  /// // URL OAuth simple
  /// final url = client.auth.getOAuthUrl('google');
  ///
  /// // Avec redirection personnalisée
  /// final url = client.auth.getOAuthUrl(
  ///   'github',
  ///   redirect: 'https://myapp.com/auth/callback',
  /// );
  ///
  /// // Ouvrir dans un navigateur
  /// await launchUrl(Uri.parse(url));
  /// ```
  String getOAuthUrl(String provider, {String? redirect}) {
    final baseUrl = _httpClient.config.baseUrl;
    var url = '$baseUrl/auth/oauth/$provider';

    if (redirect != null) {
      url += '?redirect=$redirect';
    }

    return url;
  }

  /// Connexion OAuth (à utiliser après la redirection OAuth)
  ///
  /// Cette méthode doit être appelée après que l'utilisateur a été redirigé
  /// depuis le fournisseur OAuth vers votre application avec les paramètres
  /// d'authentification.
  ///
  /// [provider] Nom du fournisseur OAuth
  /// [code] Code d'autorisation OAuth reçu dans la redirection
  /// [state] État OAuth pour la sécurité (optionnel)
  /// [mode] Mode d'authentification (json, cookie, ou session). Par défaut: json
  ///
  /// Retourne une [AuthResponse] avec les tokens
  ///
  /// ```dart
  /// // Après redirection OAuth avec code dans l'URL
  /// final response = await client.auth.loginWithOAuth(
  ///   provider: 'google',
  ///   code: 'code-from-oauth-redirect',
  /// );
  /// ```
  Future<AuthResponse> loginWithOAuth({
    required String provider,
    required String code,
    String? state,
    AuthMode mode = AuthMode.json,
  }) async {
    final response = await _httpClient.post(
      '/auth/oauth/$provider/callback',
      data: {
        'code': code,
        if (state != null) 'state': state,
        'mode': mode.toApiValue(),
      },
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

  /// Vérifie si l'utilisateur est authentifié
  bool get isAuthenticated => _httpClient.accessToken != null;

  /// Récupère le token d'accès actuel
  String? get accessToken => _httpClient.accessToken;
}
