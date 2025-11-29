import '../exceptions/directus_exception.dart';

/// Configuration pour le client Directus.
///
/// Cette classe contient toutes les informations nécessaires pour
/// se connecter à une instance Directus.
class DirectusConfig {
  /// URL de base de l'instance Directus
  final String baseUrl;

  /// Timeout pour les requêtes HTTP (en millisecondes)
  final Duration timeout;

  /// Headers personnalisés à ajouter à chaque requête
  final Map<String, String>? headers;

  /// Active ou désactive les logs
  final bool enableLogging;

  /// Callback appelé lorsque les tokens sont rafraîchis automatiquement
  ///
  /// Ce callback reçoit le nouvel access token et le nouveau refresh token (si présent).
  /// Il est appelé après chaque refresh automatique réussi, permettant de sauvegarder
  /// les nouveaux tokens dans un stockage persistant.
  ///
  /// Exemple :
  /// ```dart
  /// DirectusConfig(
  ///   baseUrl: 'https://directus.example.com',
  ///   onTokenRefreshed: (accessToken, refreshToken) async {
  ///     // Sauvegarder les nouveaux tokens
  ///     await storage.save('access_token', accessToken);
  ///     if (refreshToken != null) {
  ///       await storage.save('refresh_token', refreshToken);
  ///     }
  ///   },
  /// )
  /// ```
  final Future<void> Function(String accessToken, String? refreshToken)?
  onTokenRefreshed;

  /// Callback appelé lorsqu'une erreur d'authentification survient
  ///
  /// Ce callback est appelé dans les cas suivants :
  /// - Échec de l'auto-refresh du token (refresh token expiré/invalide)
  /// - Erreurs d'authentification DirectusAuthException
  ///
  /// Il permet à l'application de réagir aux erreurs d'authentification,
  /// par exemple en redirigeant vers l'écran de connexion.
  ///
  /// Exemple :
  /// ```dart
  /// DirectusConfig(
  ///   baseUrl: 'https://directus.example.com',
  ///   onAuthError: (exception) async {
  ///     if (exception.errorCode == 'TOKEN_EXPIRED') {
  ///       // Le refresh a échoué, rediriger vers login
  ///       await navigateToLogin();
  ///     }
  ///   },
  /// )
  /// ```
  final Future<void> Function(DirectusAuthException exception)? onAuthError;

  /// User-Agent personnalisé à ajouter aux requêtes HTTP
  ///
  /// Ce User-Agent est ajouté au User-Agent par défaut de la librairie.
  /// Le format final sera : `fcs_directus/<version> <customUserAgent>`
  ///
  /// Exemple :
  /// ```dart
  /// DirectusConfig(
  ///   baseUrl: 'https://directus.example.com',
  ///   customUserAgent: 'MyApp/1.0.0',
  /// )
  /// ```
  ///
  /// Résultat : `fcs_directus/1.0.0 MyApp/1.0.0`
  final String? customUserAgent;

  /// Crée une nouvelle configuration Directus.
  ///
  /// [baseUrl] est l'URL de base de votre instance Directus (ex: 'https://directus.example.com')
  /// [timeout] définit le timeout des requêtes (défaut: 30 secondes)
  /// [headers] permet d'ajouter des headers personnalisés
  /// [enableLogging] active les logs de debug (défaut: false)
  /// [onTokenRefreshed] callback pour notifier du refresh automatique des tokens
  /// [onAuthError] callback pour notifier des erreurs d'authentification
  /// [customUserAgent] User-Agent personnalisé à ajouter aux requêtes
  DirectusConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.headers,
    this.enableLogging = false,
    this.onTokenRefreshed,
    this.onAuthError,
    this.customUserAgent,
  }) {
    // Validation de l'URL
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      throw ArgumentError('baseUrl doit commencer par http:// ou https://');
    }
  }

  /// Copie la configuration avec de nouvelles valeurs
  DirectusConfig copyWith({
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? headers,
    bool? enableLogging,
    Future<void> Function(String accessToken, String? refreshToken)?
    onTokenRefreshed,
    Future<void> Function(DirectusAuthException exception)? onAuthError,
    String? customUserAgent,
  }) {
    return DirectusConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      timeout: timeout ?? this.timeout,
      headers: headers ?? this.headers,
      enableLogging: enableLogging ?? this.enableLogging,
      onTokenRefreshed: onTokenRefreshed ?? this.onTokenRefreshed,
      onAuthError: onAuthError ?? this.onAuthError,
      customUserAgent: customUserAgent ?? this.customUserAgent,
    );
  }

  /// Version de la librairie fcs_directus
  static const String libraryVersion = '1.0.0';

  /// Génère le User-Agent complet pour les requêtes HTTP
  ///
  /// Le format est : `fcs_directus/<version>` ou `fcs_directus/<version> <customUserAgent>`
  /// si un customUserAgent est défini.
  String get userAgent {
    final baseUserAgent = 'fcs_directus/$libraryVersion';
    if (customUserAgent != null && customUserAgent!.isNotEmpty) {
      return '$baseUserAgent $customUserAgent';
    }
    return baseUserAgent;
  }

  @override
  String toString() {
    return 'DirectusConfig(baseUrl: $baseUrl, timeout: $timeout, enableLogging: $enableLogging)';
  }
}
