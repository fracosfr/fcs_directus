# Codes d'erreur Directus

Ce document liste tous les codes d'erreur officiels de Directus et comment ils sont gérés par la librairie `fcs_directus`.

## Vue d'ensemble

La librairie `fcs_directus` implémente une gestion complète des erreurs Directus basée sur la [liste officielle des codes d'erreur](https://github.com/directus/directus/blob/main/packages/errors/src/codes.ts).

## Hiérarchie des exceptions

```
DirectusException (classe de base)
├── DirectusAuthException (401)
├── DirectusValidationException (400)
├── DirectusNotFoundException (404)
├── DirectusPermissionException (403)
├── DirectusServerException (500)
├── DirectusFileException (413)
├── DirectusRateLimitException (429)
├── DirectusMethodNotAllowedException (405)
├── DirectusDatabaseException (400)
├── DirectusRangeException (416)
├── DirectusConfigException (400)
└── DirectusNetworkException (sans code HTTP)
```

## Codes d'erreur par catégorie

### 🔐 Authentification (DirectusAuthException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_CREDENTIALS` | Identifiants invalides | 401 |
| `INVALID_TOKEN` | Token JWT invalide ou expiré | 401 |
| `TOKEN_EXPIRED` | Token JWT expiré | 401 |
| `INVALID_OTP` | Code OTP invalide | 401 |
| `USER_SUSPENDED` | Compte utilisateur suspendu | 401 |

**Exemple d'utilisation :**
```dart
try {
  await directus.auth.login(email: 'user@example.com', password: 'wrong');
} on DirectusAuthException catch (e) {
  if (e.errorCode == DirectusErrorCode.invalidCredentials.code) {
    print('Identifiants incorrects');
  } else if (e.errorCode == DirectusErrorCode.tokenExpired.code) {
    print('Session expirée, veuillez vous reconnecter');
  }
}
```

### ✅ Validation (DirectusValidationException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_PAYLOAD` | Données envoyées invalides | 400 |
| `INVALID_QUERY` | Requête invalide (paramètres incorrects) | 400 |
| `UNPROCESSABLE_CONTENT` | Contenu non traitable | 422 |
| `CONTAINS_NULL_VALUES` | Valeurs nulles non autorisées | 400 |
| `NOT_NULL_VIOLATION` | Violation de contrainte NOT NULL | 400 |
| `VALUE_OUT_OF_RANGE` | Valeur hors de la plage autorisée | 400 |
| `VALUE_TOO_LONG` | Valeur trop longue | 400 |

**Exemple d'utilisation :**
```dart
try {
  await directus.items('articles').createOne({
    'title': 'a' * 1000, // Trop long
  });
} on DirectusValidationException catch (e) {
  print('Erreur de validation: ${e.message}');
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('  $field: ${errors.join(", ")}');
    });
  }
}
```

### 🚫 Permissions (DirectusPermissionException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `FORBIDDEN` | Accès interdit (permissions insuffisantes) | 403 |

**Exemple d'utilisation :**
```dart
try {
  await directus.items('admin_settings').readMany();
} on DirectusPermissionException catch (e) {
  print('Accès refusé: ${e.message}');
  // Afficher un message à l'utilisateur ou rediriger
}
```

### 🔍 Ressources (DirectusNotFoundException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `ROUTE_NOT_FOUND` | Route ou ressource introuvable | 404 |

**Exemple d'utilisation :**
```dart
try {
  final item = await directus.items('articles').readOne('non-existent-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé');
}
```

### 🖥️ Serveur (DirectusServerException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INTERNAL_SERVER_ERROR` | Erreur interne du serveur | 500 |
| `SERVICE_UNAVAILABLE` | Service temporairement indisponible | 503 |
| `OUT_OF_DATE` | Instance Directus obsolète | 503 |

**Exemple d'utilisation :**
```dart
try {
  await directus.items('products').readMany();
} on DirectusServerException catch (e) {
  if (e.errorCode == DirectusErrorCode.serviceUnavailable.code) {
    print('Le serveur est en maintenance, veuillez réessayer plus tard');
  } else {
    print('Erreur serveur: ${e.message}');
  }
}
```

### 📁 Fichiers (DirectusFileException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `CONTENT_TOO_LARGE` | Fichier trop volumineux | 413 |
| `UNSUPPORTED_MEDIA_TYPE` | Type de média non supporté | 415 |
| `ILLEGAL_ASSET_TRANSFORMATION` | Transformation d'asset illégale | 400 |

**Exemple d'utilisation :**
```dart
try {
  await directus.files.uploadFile(
    file: largeFile,
  );
} on DirectusFileException catch (e) {
  if (e.errorCode == DirectusErrorCode.contentTooLarge.code) {
    print('Le fichier est trop volumineux');
  } else if (e.errorCode == DirectusErrorCode.unsupportedMediaType.code) {
    print('Type de fichier non supporté');
  }
}
```

### ⏱️ Rate Limiting (DirectusRateLimitException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `REQUESTS_EXCEEDED` | Trop de requêtes | 429 |
| `EMAIL_LIMIT_EXCEEDED` | Limite d'emails dépassée | 429 |
| `LIMIT_EXCEEDED` | Limite générale dépassée | 429 |

**Exemple d'utilisation :**
```dart
try {
  await directus.auth.passwordRequest(email: 'user@example.com');
} on DirectusRateLimitException catch (e) {
  print('Trop de tentatives, veuillez réessayer plus tard');
  // Attendre avant de réessayer
  await Future.delayed(Duration(minutes: 5));
}
```

### 🔧 Méthodes HTTP (DirectusMethodNotAllowedException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `METHOD_NOT_ALLOWED` | Méthode HTTP non autorisée | 405 |

**Exemple d'utilisation :**
```dart
try {
  // Tentative d'utilisation d'une méthode non supportée
  await directus.request('/endpoint', method: 'PATCH');
} on DirectusMethodNotAllowedException catch (e) {
  final allowed = e.allowedMethods;
  if (allowed != null) {
    print('Méthodes autorisées: ${allowed.join(", ")}');
  }
}
```

### 💾 Base de données (DirectusDatabaseException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_FOREIGN_KEY` | Clé étrangère invalide | 400 |
| `RECORD_NOT_UNIQUE` | Violation de contrainte d'unicité | 400 |

**Exemple d'utilisation :**
```dart
try {
  await directus.items('users').createOne({
    'email': 'existing@example.com', // Email déjà existant
  });
} on DirectusDatabaseException catch (e) {
  if (e.errorCode == DirectusErrorCode.recordNotUnique.code) {
    print('Un utilisateur avec cet email existe déjà');
    print('Collection: ${e.collection}');
    print('Champ: ${e.field}');
  }
}
```

### 📏 Range (DirectusRangeException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `RANGE_NOT_SATISFIABLE` | Plage (Range header) non satisfaisable | 416 |

**Exemple d'utilisation :**
```dart
try {
  // Requête avec un Range header invalide
  await directus.files.download('file-id', range: 'bytes=1000-2000');
} on DirectusRangeException catch (e) {
  print('Plage demandée invalide');
}
```

### ⚙️ Configuration (DirectusConfigException)

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_IP` | Adresse IP invalide ou non autorisée | 400 |
| `INVALID_PROVIDER` | Fournisseur OAuth invalide | 400 |
| `INVALID_PROVIDER_CONFIG` | Configuration du fournisseur invalide | 400 |

**Exemple d'utilisation :**
```dart
try {
  await directus.auth.loginWithProvider('invalid-provider');
} on DirectusConfigException catch (e) {
  print('Erreur de configuration: ${e.message}');
}
```

### 🌐 Réseau (DirectusNetworkException)

Exception levée lors d'erreurs réseau (pas de connexion, timeout, etc.).

**Exemple d'utilisation :**
```dart
try {
  await directus.items('articles').readMany();
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
  print('Vérifiez votre connexion internet');
}
```

## Utilisation de fromJson

La méthode factory `DirectusException.fromJson()` permet de créer automatiquement le bon type d'exception à partir d'une réponse d'erreur Directus :

```dart
final errorJson = {
  'errors': [
    {
      'message': 'Invalid credentials',
      'extensions': {
        'code': 'INVALID_CREDENTIALS'
      }
    }
  ]
};

final exception = DirectusException.fromJson(errorJson['errors'][0]);
// Type: DirectusAuthException
```

## Structure des extensions

Les exceptions Directus peuvent contenir des données supplémentaires dans le champ `extensions` :

```dart
on DirectusDatabaseException catch (e) {
  print('Code: ${e.errorCode}');
  print('Message: ${e.message}');
  print('Collection: ${e.collection}');
  print('Champ: ${e.field}');
  
  // Accès direct aux extensions
  print('Extensions: ${e.extensions}');
}
```

## Enum DirectusErrorCode

Pour faciliter la comparaison des codes d'erreur, utilisez l'enum `DirectusErrorCode` :

```dart
on DirectusException catch (e) {
  if (e.errorCode == DirectusErrorCode.tokenExpired.code) {
    // Rafraîchir le token
    await refreshToken();
  } else if (e.errorCode == DirectusErrorCode.forbidden.code) {
    // Rediriger vers la page d'accès refusé
    navigateTo('/forbidden');
  }
}
```

## Bonnes pratiques

### 1. Gestion spécifique par type

```dart
try {
  await directus.items('articles').createOne(data);
} on DirectusValidationException catch (e) {
  // Afficher les erreurs de validation à l'utilisateur
  showValidationErrors(e.fieldErrors);
} on DirectusAuthException catch (e) {
  // Rediriger vers la page de connexion
  navigateToLogin();
} on DirectusNetworkException catch (e) {
  // Afficher un message de problème réseau
  showNetworkError();
} on DirectusException catch (e) {
  // Erreur générique
  showError(e.message);
}
```

### 2. Logging centralisé

```dart
void handleDirectusError(DirectusException e) {
  // Logger l'erreur
  log('DirectusError', error: e, stackTrace: StackTrace.current);
  
  // Envoyer à un service de monitoring
  if (e is DirectusServerException) {
    analytics.logServerError(e);
  }
  
  // Afficher à l'utilisateur
  showErrorDialog(e.message);
}
```

### 3. Retry automatique

```dart
Future<T> retryOnRateLimit<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on DirectusRateLimitException catch (e) {
    // Attendre et réessayer
    await Future.delayed(Duration(seconds: 30));
    return await operation();
  }
}
```

## Mapping complet des codes vers les exceptions

| Code d'erreur | Classe d'exception | Status HTTP |
|---------------|-------------------|-------------|
| CONTAINS_NULL_VALUES | DirectusValidationException | 400 |
| CONTENT_TOO_LARGE | DirectusFileException | 413 |
| EMAIL_LIMIT_EXCEEDED | DirectusRateLimitException | 429 |
| FORBIDDEN | DirectusPermissionException | 403 |
| ILLEGAL_ASSET_TRANSFORMATION | DirectusFileException | 400 |
| INTERNAL_SERVER_ERROR | DirectusServerException | 500 |
| INVALID_CREDENTIALS | DirectusAuthException | 401 |
| INVALID_FOREIGN_KEY | DirectusDatabaseException | 400 |
| INVALID_IP | DirectusConfigException | 400 |
| INVALID_OTP | DirectusAuthException | 401 |
| INVALID_PAYLOAD | DirectusValidationException | 400 |
| INVALID_PROVIDER | DirectusConfigException | 400 |
| INVALID_PROVIDER_CONFIG | DirectusConfigException | 400 |
| INVALID_QUERY | DirectusValidationException | 400 |
| INVALID_TOKEN | DirectusAuthException | 401 |
| LIMIT_EXCEEDED | DirectusRateLimitException | 429 |
| METHOD_NOT_ALLOWED | DirectusMethodNotAllowedException | 405 |
| NOT_NULL_VIOLATION | DirectusValidationException | 400 |
| OUT_OF_DATE | DirectusServerException | 503 |
| RANGE_NOT_SATISFIABLE | DirectusRangeException | 416 |
| RECORD_NOT_UNIQUE | DirectusDatabaseException | 400 |
| REQUESTS_EXCEEDED | DirectusRateLimitException | 429 |
| ROUTE_NOT_FOUND | DirectusNotFoundException | 404 |
| SERVICE_UNAVAILABLE | DirectusServerException | 503 |
| TOKEN_EXPIRED | DirectusAuthException | 401 |
| UNPROCESSABLE_CONTENT | DirectusValidationException | 422 |
| UNSUPPORTED_MEDIA_TYPE | DirectusFileException | 415 |
| USER_SUSPENDED | DirectusAuthException | 401 |
| VALUE_OUT_OF_RANGE | DirectusValidationException | 400 |
| VALUE_TOO_LONG | DirectusValidationException | 400 |

## Références

- [Documentation officielle Directus - Error Handling](https://docs.directus.io/)
- [Codes d'erreur Directus sur GitHub](https://github.com/directus/directus/blob/main/packages/errors/src/codes.ts)
- [Package @directus/errors](https://github.com/directus/directus/tree/main/packages/errors)
