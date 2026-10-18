# Gestion des erreurs

Ce guide explique comment gérer les erreurs retournées par l'API Directus.

## Hiérarchie des exceptions

La librairie fournit une hiérarchie d'exceptions pour faciliter la gestion des erreurs :

```
DirectusException (base)
├── DirectusAuthException       # Erreurs d'authentification
├── DirectusValidationException # Erreurs de validation
├── DirectusPermissionException # Erreurs de permission
├── DirectusNotFoundException   # Ressource non trouvée
├── DirectusRateLimitException  # Rate limiting
├── DirectusNetworkException    # Erreurs réseau
└── DirectusServerException     # Erreurs serveur (5xx)
```

## Exception de base

Toutes les exceptions héritent de `DirectusException` :

```dart
try {
  await client.items('articles').readOne('invalid-id');
} on DirectusException catch (e) {
  print('Message: ${e.message}');
  print('Code erreur: ${e.errorCode}');
  print('Status HTTP: ${e.statusCode}');
  print('Détails: ${e.extensions}');
}
```

### Propriétés

| Propriété | Type | Description |
|-----------|------|-------------|
| `message` | `String` | Message d'erreur lisible |
| `errorCode` | `String?` | Code d'erreur Directus |
| `statusCode` | `int?` | Code HTTP (401, 403, 404, etc.) |
| `extensions` | `Map?` | Détails additionnels |

## DirectusAuthException

Erreurs liées à l'authentification (HTTP 401, 403) :

```dart
try {
  await client.auth.login(email: email, password: password);
} on DirectusAuthException catch (e) {
  // Helpers booléens
  if (e.isInvalidCredentials) {
    showError('Email ou mot de passe incorrect');
  } else if (e.isOtpRequired) {
    showOtpScreen();
  } else if (e.isInvalidOtp) {
    showError('Code 2FA incorrect');
  } else if (e.isUserSuspended) {
    showError('Votre compte est suspendu');
  } else if (e.isInvalidToken) {
    // Token expiré ou invalide
    await logout();
  } else {
    showError(e.message);
  }
}
```

### Helpers disponibles

| Helper | Description |
|--------|-------------|
| `isInvalidCredentials` | Email/mot de passe incorrect |
| `isOtpRequired` | Code 2FA requis |
| `isInvalidOtp` | Code 2FA incorrect |
| `isInvalidToken` | Token invalide ou expiré |
| `isUserSuspended` | Compte utilisateur suspendu |
| `isTokenExpired` | Token spécifiquement expiré |

### Vérifier un code spécifique

```dart
if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
  // Traitement spécifique
}
```

## DirectusValidationException

Erreurs de validation des données (HTTP 400) :

```dart
try {
  await client.items('articles').createOne({'title': ''});
} on DirectusValidationException catch (e) {
  print('Erreur: ${e.message}');
  
  // Erreurs par champ (si disponibles)
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('$field: ${errors.join(", ")}');
    });
    // Exemple: title: ["Title is required", "Title must be at least 3 characters"]
  }
}
```

### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| `fieldErrors` | `Map<String, List<String>>?` | Erreurs par champ |

### Affichage dans un formulaire

```dart
try {
  await saveArticle(article);
} on DirectusValidationException catch (e) {
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      // Afficher l'erreur sous le champ correspondant
      formKey.currentState?.fields[field]?.invalidate(errors.first);
    });
  }
}
```

## DirectusPermissionException

Accès refusé (HTTP 403) :

```dart
try {
  await client.items('secret_data').readMany();
} on DirectusPermissionException catch (e) {
  print('Accès refusé: ${e.message}');
  // Rediriger ou afficher un message
}
```

## DirectusNotFoundException

Ressource non trouvée (HTTP 404) :

```dart
try {
  final article = await client.items('articles').readOne('non-existent-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé');
  // Afficher une page 404 ou rediriger
}
```

## DirectusRateLimitException

Limite de requêtes atteinte (HTTP 429) :

```dart
try {
  await client.items('articles').readMany();
} on DirectusRateLimitException catch (e) {
  print('Trop de requêtes');
  
  // Attendre avant de réessayer
  await Future.delayed(Duration(seconds: 5));
  // Réessayer...
}
```

## DirectusNetworkException

Erreurs réseau (pas de connexion, timeout, etc.) :

```dart
try {
  await client.items('articles').readMany();
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
  
  // Afficher un message hors ligne
  showOfflineMessage();
}
```

## DirectusServerException

Erreurs serveur (HTTP 5xx) :

```dart
try {
  await client.items('articles').readMany();
} on DirectusServerException catch (e) {
  print('Erreur serveur: ${e.message}');
  print('Status: ${e.statusCode}');
  
  // Logger et notifier l'équipe technique
  logError(e);
}
```

## Codes d'erreur Directus

`DirectusException.fromJson` convertit le code `extensions.code` renvoyé par Directus en exception typée. Le code HTTP est conservé dans `statusCode`. L'enum `DirectusErrorCode` liste tous les codes de Directus 12 (`DirectusErrorCode.collectionInactive.code == 'COLLECTION_INACTIVE'`).

| Code(s) | Exception |
|---------|-----------|
| `INVALID_CREDENTIALS`, `INVALID_TOKEN`, `TOKEN_EXPIRED`, `INVALID_OTP`, `USER_SUSPENDED` | `DirectusAuthException` |
| `INVALID_PAYLOAD`, `INVALID_QUERY`, `UNPROCESSABLE_CONTENT`, `CONTAINS_NULL_VALUES`, `NOT_NULL_VIOLATION`, `VALUE_OUT_OF_RANGE`, `VALUE_TOO_LONG`, `INVALID_INVITE`, `INVALID_PATH_PARAMETER`, `IMPORT_CYCLICAL_RELATION`, `VERSION_HASH_MISMATCH` | `DirectusValidationException` |
| `FORBIDDEN`, `COLLECTION_INACTIVE` (12.4), `RESOURCE_RESTRICTED` | `DirectusPermissionException` |
| `ROUTE_NOT_FOUND` | `DirectusNotFoundException` |
| `INTERNAL_SERVER_ERROR`, `SERVICE_UNAVAILABLE`, `OUT_OF_DATE`, `OUT_OF_TIME`, `UNEXPECTED_RESPONSE` | `DirectusServerException` |
| `CONTENT_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `ILLEGAL_ASSET_TRANSFORMATION` | `DirectusFileException` |
| `REQUESTS_EXCEEDED`, `EMAIL_LIMIT_EXCEEDED`, `LIMIT_EXCEEDED` | `DirectusRateLimitException` |
| `METHOD_NOT_ALLOWED` | `DirectusMethodNotAllowedException` |
| `INVALID_FOREIGN_KEY`, `RECORD_NOT_UNIQUE` | `DirectusDatabaseException` |
| `RANGE_NOT_SATISFIABLE` | `DirectusRangeException` |
| `INVALID_IP`, `INVALID_PROVIDER`, `INVALID_PROVIDER_CONFIG`, `LICENSE_INVALID`, `ADDON_*` | `DirectusConfigException` |

Sans code Directus, l'exception est déduite du statut HTTP (400, 401, 403, 404, 5xx) ou de l'erreur réseau (`DirectusNetworkException`).

```dart
try {
  await client.items('archived_posts').readMany();
} on DirectusPermissionException catch (e) {
  if (e.errorCode == DirectusErrorCode.collectionInactive.code) {
    print('Collection désactivée (HTTP ${e.statusCode})');
  }
}
```

## Pattern de gestion complète

### Wrapper try-catch

```dart
Future<T?> safeCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DirectusNotFoundException catch (e) {
    showError('Ressource non trouvée');
    return null;
  } on DirectusAuthException catch (e) {
    if (e.isInvalidToken) {
      await handleTokenExpired();
    } else {
      showError(e.message);
    }
    return null;
  } on DirectusValidationException catch (e) {
    showValidationErrors(e.fieldErrors);
    return null;
  } on DirectusPermissionException catch (e) {
    showError('Vous n\'avez pas les permissions nécessaires');
    return null;
  } on DirectusRateLimitException catch (e) {
    showError('Trop de requêtes, veuillez patienter');
    return null;
  } on DirectusNetworkException catch (e) {
    showError('Erreur de connexion');
    return null;
  } on DirectusServerException catch (e) {
    showError('Erreur serveur, veuillez réessayer');
    logError(e);
    return null;
  } on DirectusException catch (e) {
    showError(e.message);
    return null;
  }
}

// Utilisation
final article = await safeCall(() => 
  client.items('articles').readOne('123')
);
```

### Gestion centralisée avec callbacks

```dart
class DirectusErrorHandler {
  void Function(String)? onError;
  void Function()? onAuthError;
  void Function()? onNetworkError;
  
  Future<T?> handle<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DirectusAuthException catch (e) {
      if (e.isInvalidToken) {
        onAuthError?.call();
      } else {
        onError?.call(e.message);
      }
    } on DirectusNetworkException {
      onNetworkError?.call();
    } on DirectusException catch (e) {
      onError?.call(e.message);
    }
    return null;
  }
}

// Configuration
final errorHandler = DirectusErrorHandler()
  ..onError = (msg) => showSnackBar(msg)
  ..onAuthError = () => navigateToLogin()
  ..onNetworkError = () => showOfflineBanner();

// Utilisation
final articles = await errorHandler.handle(() => 
  client.items('articles').readMany()
);
```

## Callback global d'erreur d'authentification

Configurez un callback pour gérer les erreurs d'auth de manière globale :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus.com',
    onAuthError: (exception) async {
      // Appelé pour toute erreur d'authentification
      // (refresh échoué, token invalide, etc.)
      
      if (exception.hasErrorCode(DirectusErrorCode.tokenExpired)) {
        // Token expiré et refresh impossible
        await clearSession();
        navigateToLogin();
      } else if (exception.isUserSuspended) {
        showSuspendedDialog();
      }
    },
  ),
);
```

## Retry automatique

Pour les erreurs temporaires :

```dart
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempts = 0;
  
  while (true) {
    try {
      return await action();
    } on DirectusRateLimitException {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
      await Future.delayed(delay * attempts);
    } on DirectusNetworkException {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
      await Future.delayed(delay * attempts);
    } on DirectusServerException catch (e) {
      if (e.statusCode == 503) {
        // Service unavailable - retry
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(delay * attempts);
      } else {
        rethrow;
      }
    }
  }
}

// Utilisation
final articles = await withRetry(() => 
  client.items('articles').readMany()
);
```

## Logging des erreurs

```dart
void logDirectusError(DirectusException e) {
  final log = {
    'type': e.runtimeType.toString(),
    'message': e.message,
    'errorCode': e.errorCode,
    'statusCode': e.statusCode,
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  // Envoyer à votre service de logging
  logger.error(log);
  
  // Ou Firebase Crashlytics
  FirebaseCrashlytics.instance.recordError(
    e,
    StackTrace.current,
    reason: 'Directus API Error',
  );
}
```

## Bonnes pratiques

### 1. Toujours gérer les erreurs

```dart
// ❌ Pas de gestion d'erreur
final article = await client.items('articles').readOne('123');

// ✅ Avec gestion
try {
  final article = await client.items('articles').readOne('123');
} on DirectusException catch (e) {
  handleError(e);
}
```

### 2. Être spécifique

```dart
// ❌ Catch trop générique
try {
  await action();
} catch (e) {
  print(e);
}

// ✅ Catch spécifique
try {
  await action();
} on DirectusNotFoundException {
  // Traitement 404
} on DirectusAuthException catch (e) {
  // Traitement auth
} on DirectusException catch (e) {
  // Autres erreurs Directus
}
```

### 3. Messages utilisateur clairs

```dart
String getUserMessage(DirectusException e) {
  if (e is DirectusNotFoundException) {
    return 'L\'élément demandé n\'existe pas';
  }
  if (e is DirectusAuthException) {
    if (e.isInvalidCredentials) return 'Identifiants incorrects';
    if (e.isUserSuspended) return 'Compte suspendu';
    return 'Problème d\'authentification';
  }
  if (e is DirectusValidationException) {
    return 'Données invalides';
  }
  if (e is DirectusPermissionException) {
    return 'Accès refusé';
  }
  if (e is DirectusNetworkException) {
    return 'Problème de connexion';
  }
  return 'Une erreur est survenue';
}
```

### 4. Logger pour le debug

En développement, loggez les erreurs complètes :

```dart
if (kDebugMode) {
  print('=== Directus Error ===');
  print('Type: ${e.runtimeType}');
  print('Message: ${e.message}');
  print('Code: ${e.errorCode}');
  print('Status: ${e.statusCode}');
  print('Extensions: ${e.extensions}');
  print('=====================');
}
```
