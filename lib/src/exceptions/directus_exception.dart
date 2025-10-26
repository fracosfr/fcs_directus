/// Codes d'erreur Directus officiels
/// Source: https://github.com/directus/directus/blob/main/packages/errors/src/codes.ts
enum DirectusErrorCode {
  containsNullValues('CONTAINS_NULL_VALUES'),
  contentTooLarge('CONTENT_TOO_LARGE'),
  emailLimitExceeded('EMAIL_LIMIT_EXCEEDED'),
  forbidden('FORBIDDEN'),
  illegalAssetTransformation('ILLEGAL_ASSET_TRANSFORMATION'),
  internal('INTERNAL_SERVER_ERROR'),
  invalidCredentials('INVALID_CREDENTIALS'),
  invalidForeignKey('INVALID_FOREIGN_KEY'),
  invalidIp('INVALID_IP'),
  invalidOtp('INVALID_OTP'),
  invalidPayload('INVALID_PAYLOAD'),
  invalidProvider('INVALID_PROVIDER'),
  invalidProviderConfig('INVALID_PROVIDER_CONFIG'),
  invalidQuery('INVALID_QUERY'),
  invalidToken('INVALID_TOKEN'),
  limitExceeded('LIMIT_EXCEEDED'),
  methodNotAllowed('METHOD_NOT_ALLOWED'),
  notNullViolation('NOT_NULL_VIOLATION'),
  outOfDate('OUT_OF_DATE'),
  rangeNotSatisfiable('RANGE_NOT_SATISFIABLE'),
  recordNotUnique('RECORD_NOT_UNIQUE'),
  requestsExceeded('REQUESTS_EXCEEDED'),
  routeNotFound('ROUTE_NOT_FOUND'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  tokenExpired('TOKEN_EXPIRED'),
  unprocessableContent('UNPROCESSABLE_CONTENT'),
  unsupportedMediaType('UNSUPPORTED_MEDIA_TYPE'),
  userSuspended('USER_SUSPENDED'),
  valueOutOfRange('VALUE_OUT_OF_RANGE'),
  valueTooLong('VALUE_TOO_LONG');

  const DirectusErrorCode(this.code);
  final String code;
}

/// Exception de base pour toutes les erreurs liées à Directus.
///
/// Toutes les exceptions spécifiques héritent de cette classe.
class DirectusException implements Exception {
  /// Message d'erreur
  final String message;

  /// Code d'erreur HTTP (si applicable)
  final int? statusCode;

  /// Code d'erreur Directus (si applicable)
  final String? errorCode;

  /// Données supplémentaires sur l'erreur (extensions)
  final Map<String, dynamic>? extensions;

  /// Crée une nouvelle exception Directus
  DirectusException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.extensions,
  });

  /// Crée une exception à partir d'une réponse d'erreur Directus
  factory DirectusException.fromJson(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? 'Unknown error';
    final extensions = json['extensions'] as Map<String, dynamic>?;
    final errorCode = extensions?['code'] as String?;

    // Mapper le code d'erreur vers le type d'exception approprié
    if (errorCode != null) {
      switch (errorCode) {
        case 'INVALID_CREDENTIALS':
        case 'INVALID_TOKEN':
        case 'TOKEN_EXPIRED':
        case 'INVALID_OTP':
        case 'USER_SUSPENDED':
          return DirectusAuthException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'INVALID_PAYLOAD':
        case 'INVALID_QUERY':
        case 'UNPROCESSABLE_CONTENT':
        case 'CONTAINS_NULL_VALUES':
        case 'NOT_NULL_VIOLATION':
        case 'VALUE_OUT_OF_RANGE':
        case 'VALUE_TOO_LONG':
          return DirectusValidationException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'ROUTE_NOT_FOUND':
          return DirectusNotFoundException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'FORBIDDEN':
          return DirectusPermissionException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'INTERNAL_SERVER_ERROR':
        case 'SERVICE_UNAVAILABLE':
        case 'OUT_OF_DATE':
          return DirectusServerException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'CONTENT_TOO_LARGE':
        case 'UNSUPPORTED_MEDIA_TYPE':
        case 'ILLEGAL_ASSET_TRANSFORMATION':
          return DirectusFileException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'REQUESTS_EXCEEDED':
        case 'EMAIL_LIMIT_EXCEEDED':
        case 'LIMIT_EXCEEDED':
          return DirectusRateLimitException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'METHOD_NOT_ALLOWED':
          return DirectusMethodNotAllowedException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'INVALID_FOREIGN_KEY':
        case 'RECORD_NOT_UNIQUE':
          return DirectusDatabaseException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'RANGE_NOT_SATISFIABLE':
          return DirectusRangeException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );

        case 'INVALID_IP':
        case 'INVALID_PROVIDER':
        case 'INVALID_PROVIDER_CONFIG':
          return DirectusConfigException(
            message: message,
            errorCode: errorCode,
            extensions: extensions,
          );
      }
    }

    return DirectusException(
      message: message,
      errorCode: errorCode,
      extensions: extensions,
    );
  }

  @override
  String toString() {
    final parts = <String>['DirectusException'];
    if (errorCode != null) parts.add('[$errorCode]');
    if (statusCode != null) parts.add('($statusCode)');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs d'authentification
/// Codes: INVALID_CREDENTIALS, INVALID_TOKEN, TOKEN_EXPIRED, INVALID_OTP, USER_SUSPENDED
class DirectusAuthException extends DirectusException {
  DirectusAuthException({
    required super.message,
    super.statusCode = 401,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusAuthException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de validation
/// Codes: INVALID_PAYLOAD, INVALID_QUERY, UNPROCESSABLE_CONTENT, CONTAINS_NULL_VALUES,
/// NOT_NULL_VIOLATION, VALUE_OUT_OF_RANGE, VALUE_TOO_LONG
class DirectusValidationException extends DirectusException {
  DirectusValidationException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.extensions,
  });

  /// Récupère les erreurs de validation par champ depuis les extensions
  Map<String, List<String>>? get fieldErrors {
    if (extensions == null) return null;
    // Tenter de parser les erreurs de champs depuis les extensions
    final errors = extensions!['field_errors'];
    if (errors is Map) {
      return errors.map((key, value) => MapEntry(
            key.toString(),
            value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
          ));
    }
    return null;
  }

  @override
  String toString() {
    final parts = <String>['DirectusValidationException'];
    if (errorCode != null) parts.add('[$errorCode]');
    final fe = fieldErrors;
    if (fe != null && fe.isNotEmpty) {
      parts.add(': $message (Fields: ${fe.keys.join(", ")})');
    } else {
      parts.add(': $message');
    }
    return parts.join(' ');
  }
}

/// Exception levée lorsqu'une ressource n'est pas trouvée
/// Code: ROUTE_NOT_FOUND
class DirectusNotFoundException extends DirectusException {
  DirectusNotFoundException({
    required super.message,
    super.statusCode = 404,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusNotFoundException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs réseau
class DirectusNetworkException extends DirectusException {
  DirectusNetworkException({
    required super.message,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() => 'DirectusNetworkException: $message';
}

/// Exception levée lors d'erreurs serveur
/// Codes: INTERNAL_SERVER_ERROR, SERVICE_UNAVAILABLE, OUT_OF_DATE
class DirectusServerException extends DirectusException {
  DirectusServerException({
    required super.message,
    super.statusCode = 500,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusServerException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de permission
/// Code: FORBIDDEN
class DirectusPermissionException extends DirectusException {
  DirectusPermissionException({
    required super.message,
    super.statusCode = 403,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusPermissionException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs liées aux fichiers
/// Codes: CONTENT_TOO_LARGE, UNSUPPORTED_MEDIA_TYPE, ILLEGAL_ASSET_TRANSFORMATION
class DirectusFileException extends DirectusException {
  DirectusFileException({
    required super.message,
    super.statusCode = 413,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusFileException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de limitation de taux (rate limiting)
/// Codes: REQUESTS_EXCEEDED, EMAIL_LIMIT_EXCEEDED, LIMIT_EXCEEDED
class DirectusRateLimitException extends DirectusException {
  DirectusRateLimitException({
    required super.message,
    super.statusCode = 429,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusRateLimitException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de méthode non autorisée
/// Code: METHOD_NOT_ALLOWED
class DirectusMethodNotAllowedException extends DirectusException {
  DirectusMethodNotAllowedException({
    required super.message,
    super.statusCode = 405,
    super.errorCode,
    super.extensions,
  });

  /// Liste des méthodes HTTP autorisées
  List<String>? get allowedMethods {
    if (extensions == null) return null;
    final allowed = extensions!['allowed'];
    if (allowed is List) {
      return allowed.map((e) => e.toString()).toList();
    }
    return null;
  }

  @override
  String toString() {
    final parts = <String>['DirectusMethodNotAllowedException'];
    if (errorCode != null) parts.add('[$errorCode]');
    final methods = allowedMethods;
    if (methods != null && methods.isNotEmpty) {
      parts.add(': $message (Allowed: ${methods.join(", ")})');
    } else {
      parts.add(': $message');
    }
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de base de données
/// Codes: INVALID_FOREIGN_KEY, RECORD_NOT_UNIQUE
class DirectusDatabaseException extends DirectusException {
  DirectusDatabaseException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.extensions,
  });

  /// Nom de la collection concernée
  String? get collection => extensions?['collection'] as String?;

  /// Nom du champ concerné
  String? get field => extensions?['field'] as String?;

  @override
  String toString() {
    final parts = <String>['DirectusDatabaseException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    if (collection != null) parts.add(' (Collection: $collection)');
    if (field != null) parts.add(' (Field: $field)');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de plage (range)
/// Code: RANGE_NOT_SATISFIABLE
class DirectusRangeException extends DirectusException {
  DirectusRangeException({
    required super.message,
    super.statusCode = 416,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusRangeException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}

/// Exception levée lors d'erreurs de configuration
/// Codes: INVALID_IP, INVALID_PROVIDER, INVALID_PROVIDER_CONFIG
class DirectusConfigException extends DirectusException {
  DirectusConfigException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.extensions,
  });

  @override
  String toString() {
    final parts = <String>['DirectusConfigException'];
    if (errorCode != null) parts.add('[$errorCode]');
    parts.add(': $message');
    return parts.join(' ');
  }
}
