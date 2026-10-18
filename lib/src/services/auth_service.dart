import 'package:dio/dio.dart';
import '../core/directus_http_client.dart';
import '../exceptions/directus_exception.dart';

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
      // En mode `session`, Directus ne renvoie pas de token (il est en cookie).
      accessToken: json['access_token'] as String? ?? '',
      expiresIn: json['expires'] as int? ?? 0,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}

/// Fournisseur d'authentification configuré sur le serveur (`GET /auth`).
///
/// Couvre les drivers SSO (`oauth2`, `openid`, `saml`) et `ldap`.
class OAuthProvider {
  /// Nom du fournisseur (ex: 'google', 'github', 'keycloak').
  final String name;

  /// Driver Directus (`oauth2`, `openid`, `saml`, `ldap`).
  final String? driver;

  /// Libellé affiché sur le bouton de connexion.
  final String? label;

  /// Icône du fournisseur (SVG ou URL).
  final String? icon;

  OAuthProvider({required this.name, this.driver, this.label, this.icon});

  factory OAuthProvider.fromJson(Map<String, dynamic> json) {
    return OAuthProvider(
      name: json['name'] as String,
      driver: json['driver'] as String?,
      label: json['label'] as String?,
      icon: json['icon'] as String?,
    );
  }

  /// Vrai pour un fournisseur à redirection navigateur (OAuth2/OpenID/SAML).
  bool get isSso => driver != 'ldap';

  Map<String, dynamic> toJson() => {
    'name': name,
    if (driver != null) 'driver': driver,
    if (label != null) 'label': label,
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

    return _storeTokens(response.data['data'] as Map<String, dynamic>);
  }

  /// Connexion via un fournisseur d'authentification nommé
  /// (`POST /auth/login/{provider}`), typiquement LDAP.
  ///
  /// [identifier] Identifiant LDAP (ou email selon le driver)
  ///
  /// ```dart
  /// await client.auth.loginWithProvider(
  ///   provider: 'ldap',
  ///   identifier: 'jdoe',
  ///   password: 'secret',
  /// );
  /// ```
  Future<AuthResponse> loginWithProvider({
    required String provider,
    required String identifier,
    required String password,
    String? otp,
    AuthMode mode = AuthMode.json,
  }) async {
    final response = await _httpClient.post(
      '/auth/login/$provider',
      data: {
        'identifier': identifier,
        'password': password,
        if (otp != null) 'otp': otp,
        'mode': mode.toApiValue(),
      },
    );
    return _storeTokens(response.data['data'] as Map<String, dynamic>);
  }

  /// Convertit la réponse d'auth et mémorise les tokens (s'il y en a).
  AuthResponse _storeTokens(Map<String, dynamic> data) {
    final authResponse = AuthResponse.fromJson(data);
    if (authResponse.accessToken.isNotEmpty) {
      _httpClient.setTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
    }
    return authResponse;
  }

  /// Connexion avec un token statique
  ///
  /// [token] Token statique généré depuis Directus
  Future<void> loginWithToken(String token) async {
    _httpClient.setTokens(accessToken: token);
  }

  /// Restaure une session avec un refresh token
  ///
  /// Cette méthode est utile pour restaurer une session après un redémarrage
  /// de l'application. Elle utilise le refresh token pour obtenir un nouveau
  /// access token.
  ///
  /// [refreshToken] Token de rafraîchissement sauvegardé
  /// [mode] Mode d'authentification (json, cookie, ou session). Par défaut: json
  ///
  /// Retourne une [AuthResponse] avec le nouvel access token
  ///
  /// ```dart
  /// // Sauvegarder les tokens après login
  /// final authResponse = await client.auth.login(
  ///   email: 'user@example.com',
  ///   password: 'password',
  /// );
  /// await storage.save('refresh_token', authResponse.refreshToken);
  ///
  /// // Restaurer la session plus tard
  /// final savedRefreshToken = await storage.load('refresh_token');
  /// final newAuth = await client.auth.restoreSession(savedRefreshToken);
  /// print('Session restaurée, nouveau token expire dans ${newAuth.expiresIn}s');
  /// ```
  ///
  /// Voir aussi : [refresh] pour rafraîchir une session existante
  Future<AuthResponse> restoreSession(
    String refreshToken, {
    AuthMode mode = AuthMode.json,
  }) async {
    return await refresh(refreshToken: refreshToken, mode: mode);
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

    // En mode cookie/session le refresh token est lu dans le cookie httpOnly.
    if (token == null && mode == AuthMode.json) {
      throw Exception('Aucun refresh token disponible');
    }

    // Utiliser un Dio temporaire SANS intercepteurs pour éviter que
    // l'intercepteur auto-refresh ne consomme le refresh token avant nous.
    // C'est le même pattern que _performRefresh() dans DirectusHttpClient.
    final refreshHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_httpClient.config.userAgent != null) {
      refreshHeaders['User-Agent'] = _httpClient.config.userAgent!;
    }
    if (_httpClient.config.headers != null) {
      refreshHeaders.addAll(_httpClient.config.headers!);
    }

    final tempDio = Dio(
      BaseOptions(
        baseUrl: _httpClient.config.baseUrl,
        connectTimeout: _httpClient.config.timeout,
        receiveTimeout: _httpClient.config.timeout,
        headers: refreshHeaders,
      ),
    );

    final Response<Map<String, dynamic>> response;
    try {
      response = await tempDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          if (token != null) 'refresh_token': token,
          'mode': mode.toApiValue(),
        },
      );
    } on DioException catch (e) {
      throw _httpClient.handleDioError(e);
    }

    if (response.data == null || !response.data!.containsKey('data')) {
      throw DirectusAuthException(
        message: 'Invalid refresh response',
        errorCode: 'INVALID_REFRESH_RESPONSE',
      );
    }

    final authResponse = AuthResponse.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );

    // Mettre à jour les tokens (aucun token en mode session)
    if (authResponse.accessToken.isNotEmpty) {
      _httpClient.setTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken ?? token,
      );
    }

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

    // Supprimer les tokens localement et nettoyer les états internes
    _httpClient.clearTokens();
  }

  /// Définit manuellement les tokens d'authentification
  ///
  /// Cette méthode est utile pour restaurer une session depuis un stockage local
  /// sans faire d'appel réseau (contrairement à [restoreSession]).
  ///
  /// [accessToken] Token d'accès
  /// [refreshToken] Token de rafraîchissement (optionnel)
  ///
  /// ```dart
  /// // Restaurer les tokens depuis le stockage local
  /// final savedAccessToken = await storage.load('access_token');
  /// final savedRefreshToken = await storage.load('refresh_token');
  ///
  /// client.auth.setTokens(
  ///   accessToken: savedAccessToken,
  ///   refreshToken: savedRefreshToken,
  /// );
  ///
  /// // Ensuite, vérifier que la session est valide
  /// try {
  ///   await client.users.me();
  ///   print('Session restaurée avec succès');
  /// } catch (e) {
  ///   print('Session invalide, reconnexion nécessaire');
  ///   client.clearTokens();
  /// }
  /// ```
  void setTokens({String? accessToken, String? refreshToken}) {
    _httpClient.setTokens(accessToken: accessToken, refreshToken: refreshToken);
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

  /// Liste les fournisseurs d'authentification configurés (`GET /auth`).
  ///
  /// ```dart
  /// final providers = await client.auth.listOAuthProviders();
  /// for (final p in providers.where((p) => p.isSso)) {
  ///   print('${p.label ?? p.name} (${p.driver})');
  /// }
  /// ```
  Future<List<OAuthProvider>> listOAuthProviders({
    bool sessionOnly = false,
  }) async {
    final response = await _httpClient.get(
      '/auth',
      queryParameters: sessionOnly ? {'sessionOnly': true} : null,
    );

    final data = response.data['data'] as List;
    return data
        .map((json) => OAuthProvider.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Génère l'URL de connexion SSO d'un fournisseur
  /// (`GET /auth/login/{provider}`).
  ///
  /// Flux SSO Directus (OAuth2 / OpenID / SAML) :
  /// 1. ouvrir cette URL dans un navigateur (ou une WebView) ;
  /// 2. Directus redirige vers le fournisseur puis vers [redirect] ;
  /// 3. le refresh token est déposé en cookie `httpOnly` sur le domaine Directus
  ///    (ou un cookie de session si `mode=session` est géré côté serveur) ;
  /// 4. appeler [refresh] avec `mode: AuthMode.cookie` depuis un contexte qui
  ///    partage ces cookies (Flutter Web, WebView), ou récupérer le token
  ///    côté serveur et utiliser [restoreSession].
  ///
  /// [redirect] doit être autorisé par `AUTH_<PROVIDER>_REDIRECT_ALLOW_LIST`.
  ///
  /// ```dart
  /// final url = client.auth.getOAuthUrl(
  ///   'google',
  ///   redirect: 'https://myapp.com/auth/callback',
  /// );
  /// await launchUrl(Uri.parse(url));
  /// ```
  String getOAuthUrl(String provider, {String? redirect}) {
    final uri = Uri.parse('${_httpClient.config.baseUrl}/auth/login/$provider');
    return uri
        .replace(
          queryParameters: redirect != null ? {'redirect': redirect} : null,
        )
        .toString();
  }

  /// Ancien échange de code OAuth.
  ///
  /// Directus n'expose aucun endpoint JSON d'échange de code : le callback est
  /// traité côté serveur et la session est déposée en cookie. Utiliser
  /// [getOAuthUrl] puis [refresh] (`mode: AuthMode.cookie`).
  @Deprecated(
    'Directus ne fournit pas d\'échange de code OAuth en JSON. '
    'Utiliser getOAuthUrl() puis refresh(mode: AuthMode.cookie).',
  )
  Future<AuthResponse> loginWithOAuth({
    required String provider,
    required String code,
    String? state,
    AuthMode mode = AuthMode.json,
  }) async {
    throw UnsupportedError(
      'Directus ne fournit pas d\'échange de code OAuth en JSON. '
      'Utiliser getOAuthUrl() puis refresh(mode: AuthMode.cookie).',
    );
  }

  /// Vérifie si l'utilisateur est authentifié
  bool get isAuthenticated => _httpClient.accessToken != null;

  /// Récupère le token d'accès actuel
  String? get accessToken => _httpClient.accessToken;
}
