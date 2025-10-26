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

  /// Crée une nouvelle configuration Directus.
  ///
  /// [baseUrl] est l'URL de base de votre instance Directus (ex: 'https://directus.example.com')
  /// [timeout] définit le timeout des requêtes (défaut: 30 secondes)
  /// [headers] permet d'ajouter des headers personnalisés
  /// [enableLogging] active les logs de debug (défaut: false)
  DirectusConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.headers,
    this.enableLogging = false,
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
  }) {
    return DirectusConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      timeout: timeout ?? this.timeout,
      headers: headers ?? this.headers,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }

  @override
  String toString() {
    return 'DirectusConfig(baseUrl: $baseUrl, timeout: $timeout, enableLogging: $enableLogging)';
  }
}
