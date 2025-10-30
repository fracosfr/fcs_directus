# Exceptions API Reference

Documentation complète des exceptions dans fcs_directus.

## Hiérarchie des exceptions

```
DirectusException (base)
├── DirectusAuthException
├── DirectusValidationException
├── DirectusNotFoundException
└── DirectusNetworkException
```

## DirectusException

Exception de base pour toutes les erreurs Directus.

### Propriétés

```dart
class DirectusException implements Exception {
  /// Message d'erreur
  final String message;
  
  /// Code HTTP (ex: 400, 401, 404, 500)
  final int? code;
  
  /// Erreurs détaillées depuis l'API
  final Map<String, dynamic>? errors;
  
  DirectusException(this.message, {this.code, this.errors});
}
```

### Utilisation

```dart
try {
  await directus.items('articles').readMany();
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
  print('Code: ${e.code}');
  print('Détails: ${e.errors}');
}
```

## DirectusAuthException

Erreurs d'authentification et d'autorisation.

### Codes HTTP courants

- `401 Unauthorized` : Credentials invalides ou token expiré
- `403 Forbidden` : Permissions insuffisantes

### Helpers disponibles

- `isOtpRequired` : OTP requis (2FA activée)
- `isInvalidCredentials` : Credentials invalides
- `isInvalidToken` : Token invalide ou expiré
- `isUserSuspended` : Utilisateur suspendu
- `hasErrorCode(DirectusErrorCode)` : Vérifier un code spécifique

### Cas d'usage

```dart
try {
  await directus.auth.login(
    email: 'user@example.com',
    password: 'wrong-password',
  );
} on DirectusAuthException catch (e) {
  // Utiliser les helpers (recommandé)
  if (e.isInvalidCredentials) {
    showError('Email ou mot de passe incorrect');
  } else if (e.isOtpRequired) {
    showOtpDialog();
  } else if (e.isInvalidToken) {
    showError('Session expirée');
  }
  
  // Ou vérifier avec DirectusErrorCode
  if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
    showError('Code 2FA invalide');
  }
}

// Erreur 403 : Utiliser DirectusPermissionException
try {
  await directus.items('admin_only').readMany();
} on DirectusPermissionException catch (e) {
  showError('Accès non autorisé');
}
```

### Messages courants

- `"Invalid user credentials"` : Login failed
- `"Token expired"` : Access token expiré
- `"Invalid token"` : Token corrompu ou invalide
- `"Invalid OTP"` : Code 2FA incorrect
## DirectusValidationException

Erreurs de validation des données.

### Propriétés additionnelles

```dart
class DirectusValidationException extends DirectusException {
  /// Erreurs par champ
  /// Map<field_name, List<error_messages>>
  Map<String, List<String>> get fieldErrors;
  
  DirectusValidationException(
    String message, {
    int? code,
    Map<String, dynamic>? errors,
  }) : super(message, code: code, errors: errors);
}
```

### Structure des erreurs

```dart
{
  'email': ['Email invalide', 'Email déjà utilisé'],
  'password': ['Minimum 8 caractères', 'Doit contenir un chiffre'],
  'age': ['Doit être supérieur à 18'],
}
```

### Utilisation

```dart
try {
  await directus.users.createOne(item: {
    'email': 'invalid-email',
    'password': '123',
  });
} on DirectusValidationException catch (e) {
  print('Validation échouée:');
  
  for (final entry in e.fieldErrors.entries) {
    final field = entry.key;
    final errors = entry.value;
    print('$field: ${errors.join(', ')}');
  }
}
```

### Dans un formulaire Flutter

```dart
Map<String, String> _fieldErrors = {};

try {
  await directus.items('articles').createOne(item: formData);
} on DirectusValidationException catch (e) {
  setState(() {
    _fieldErrors = e.fieldErrors.map(
      (key, value) => MapEntry(key, value.join(', ')),
    );
  });
}

// Dans le widget
TextFormField(
  decoration: InputDecoration(
    errorText: _fieldErrors['title'],
  ),
)
```

## DirectusNotFoundException

Ressource non trouvée (404).

### Cas d'usage

```dart
try {
  final article = await directus.items('articles').readOne(
    id: 'non-existent-id',
  );
} on DirectusNotFoundException catch (e) {
  // L'article n'existe pas
  showError('Article introuvable');
  Navigator.pop(context);
}
```

### Messages courants

- `"Item not found"` : Item avec cet ID n'existe pas
- `"Collection not found"` : Collection n'existe pas
- `"User not found"` : Utilisateur introuvable

## DirectusNetworkException

Erreurs réseau (timeout, connexion perdue, etc.).

### Causes courantes

- Timeout de connexion
- Pas de connexion internet
- Serveur inaccessible
- DNS ne résout pas
- Certificat SSL invalide

### Utilisation

```dart
try {
  await directus.items('articles').readMany();
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
  
  // Afficher un message approprié
  showError('Vérifiez votre connexion internet');
  
  // Proposer de réessayer
  showRetryButton();
}
```

### Gestion du timeout

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    timeout: Duration(seconds: 30),
  ),
);

try {
  await directus.items('large_collection').readMany();
} on DirectusNetworkException catch (e) {
  if (e.message.contains('timeout')) {
    showError('La requête a pris trop de temps');
  }
}
```

## Gestion globale des erreurs

### Pattern recommandé

```dart
Future<T?> handleDirectusCall<T>(
  Future<T> Function() operation, {
  BuildContext? context,
}) async {
  try {
    return await operation();
  } on DirectusAuthException catch (e) {
    if (context != null) {
      Navigator.pushNamed(context, '/login');
      showError(context, 'Session expirée. Veuillez vous reconnecter.');
    }
    return null;
  } on DirectusValidationException catch (e) {
    if (context != null) {
      showValidationErrors(context, e.fieldErrors);
    }
    return null;
  } on DirectusNotFoundException catch (e) {
    if (context != null) {
      showError(context, 'Ressource introuvable');
    }
    return null;
  } on DirectusNetworkException catch (e) {
    if (context != null) {
      showError(context, 'Erreur de connexion. Vérifiez votre internet.');
    }
    return null;
  } on DirectusException catch (e) {
    if (context != null) {
      showError(context, e.message);
    }
    return null;
  } catch (e) {
    if (context != null) {
      showError(context, 'Une erreur inattendue s\'est produite');
    }
    return null;
  }
}
```

## Codes HTTP de référence

### 2xx Success

- `200 OK` : Requête réussie
- `201 Created` : Ressource créée
- `204 No Content` : Succès sans contenu (ex: delete)

### 4xx Client Errors

- `400 Bad Request` : Données invalides
- `401 Unauthorized` : Non authentifié
- `403 Forbidden` : Non autorisé
- `404 Not Found` : Ressource introuvable
- `422 Unprocessable Entity` : Erreurs de validation

### 5xx Server Errors

- `500 Internal Server Error` : Erreur serveur
- `502 Bad Gateway` : Proxy/gateway error
- `503 Service Unavailable` : Service temporairement indisponible

## Logging des erreurs

### Logger simple

```dart
void logError(dynamic error, [StackTrace? stackTrace]) {
  if (error is DirectusException) {
    print('╔════════════════════════════════════════╗');
    print('║ DIRECTUS ERROR                         ║');
    print('╠════════════════════════════════════════╣');
    print('║ Type: ${error.runtimeType}');
    print('║ Message: ${error.message}');
    print('║ Code: ${error.code}');
    if (error.errors != null) {
      print('║ Errors: ${error.errors}');
    }
    print('╚════════════════════════════════════════╝');
  } else {
    print('Unexpected error: $error');
  }
  
  if (stackTrace != null) {
    print(stackTrace);
  }
}
```

### Intégration Sentry

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void reportError(dynamic error, StackTrace stackTrace) {
  Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: error is DirectusException ? {
      'directus_code': error.code,
      'directus_message': error.message,
      'directus_errors': error.errors,
    } : null,
  );
}
```

## Tests

### Tester les exceptions

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('throws DirectusAuthException on invalid credentials', () async {
    final mockAuth = MockAuthService();
    
    when(mockAuth.login(email: any, password: any))
        .thenThrow(DirectusAuthException(
          'Invalid credentials',
          code: 401,
        ));
    
    expect(
      () => mockAuth.login(email: 'test@test.com', password: 'wrong'),
      throwsA(isA<DirectusAuthException>()),
    );
  });
  
  test('handles validation errors correctly', () async {
    final mockItems = MockItemsService();
    
    when(mockItems.createOne(item: any))
        .thenThrow(DirectusValidationException(
          'Validation failed',
          code: 422,
          errors: {
            'email': ['Email invalide'],
            'password': ['Trop court'],
          },
        ));
    
    try {
      await mockItems.createOne(item: {});
      fail('Should throw exception');
    } on DirectusValidationException catch (e) {
      expect(e.fieldErrors['email'], ['Email invalide']);
      expect(e.fieldErrors['password'], ['Trop court']);
    }
  });
}
```

## Voir aussi

- [Error Handling Guide](../11-error-handling.md)
- [Authentication](../03-authentication.md)
- [Models](../04-models.md)
