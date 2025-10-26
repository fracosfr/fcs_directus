/// Exception de base pour toutes les erreurs liées à Directus.
///
/// Toutes les exceptions spécifiques héritent de cette classe.
class DirectusException implements Exception {
  /// Message d'erreur
  final String message;

  /// Code d'erreur HTTP (si applicable)
  final int? statusCode;

  /// Données supplémentaires sur l'erreur
  final dynamic data;

  /// Crée une nouvelle exception Directus
  DirectusException({required this.message, this.statusCode, this.data});

  @override
  String toString() {
    if (statusCode != null) {
      return 'DirectusException [$statusCode]: $message';
    }
    return 'DirectusException: $message';
  }
}

/// Exception levée lors d'erreurs d'authentification
class DirectusAuthException extends DirectusException {
  DirectusAuthException({required super.message, super.statusCode, super.data});

  @override
  String toString() => 'DirectusAuthException: $message';
}

/// Exception levée lors d'erreurs de validation
class DirectusValidationException extends DirectusException {
  /// Erreurs de validation par champ
  final Map<String, List<String>>? fieldErrors;

  DirectusValidationException({
    required super.message,
    super.statusCode,
    super.data,
    this.fieldErrors,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'DirectusValidationException: $message\nFields: ${fieldErrors!.keys.join(", ")}';
    }
    return 'DirectusValidationException: $message';
  }
}

/// Exception levée lorsqu'une ressource n'est pas trouvée
class DirectusNotFoundException extends DirectusException {
  DirectusNotFoundException({
    required super.message,
    super.statusCode = 404,
    super.data,
  });

  @override
  String toString() => 'DirectusNotFoundException: $message';
}

/// Exception levée lors d'erreurs réseau
class DirectusNetworkException extends DirectusException {
  DirectusNetworkException({required super.message, super.data});

  @override
  String toString() => 'DirectusNetworkException: $message';
}

/// Exception levée lors d'erreurs serveur
class DirectusServerException extends DirectusException {
  DirectusServerException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'DirectusServerException: $message';
}

/// Exception levée lors d'erreurs de permission
class DirectusPermissionException extends DirectusException {
  DirectusPermissionException({
    required super.message,
    super.statusCode = 403,
    super.data,
  });

  @override
  String toString() => 'DirectusPermissionException: $message';
}
