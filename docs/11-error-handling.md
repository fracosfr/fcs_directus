# Error Handling

Guide complet de la gestion des erreurs dans fcs_directus.

## 🚨 Types d'exceptions

fcs_directus fournit une hiérarchie d'exceptions pour gérer tous les cas d'erreur.

### DirectusException (Base)

Exception de base pour toutes les erreurs Directus.

```dart
class DirectusException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? extensions;
  
  // ...
}
```

**Propriétés communes** :
- `message` : Message d'erreur lisible
- `statusCode` : Code HTTP (401, 404, 500, etc.)
- `errorCode` : Code d'erreur Directus (INVALID_CREDENTIALS, etc.)
- `extensions` : Données supplémentaires

### DirectusAuthException

Erreurs d'authentification et d'autorisation.

```dart
try {
  await directus.auth.login(email: 'wrong@email.com', password: 'wrong');
} on DirectusAuthException catch (e) {
  // Utiliser les helpers (recommandé)
  if (e.isOtpRequired) {
    print('Code OTP requis');
  }
  if (e.isInvalidCredentials) {
    print('Email ou mot de passe incorrect');
  }
  if (e.isInvalidToken) {
    print('Token invalide ou expiré');
  }
  if (e.isUserSuspended) {
    print('Compte suspendu');
  }
  
  // Ou vérifier avec DirectusErrorCode
  if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
    print('OTP invalide');
  }
  
  print('Erreur auth: ${e.message}');
  print('Code HTTP: ${e.statusCode}'); // 401
  print('Code erreur: ${e.errorCode}'); // INVALID_CREDENTIALS
}
```

**Helpers disponibles** :
- `isOtpRequired` : OTP requis ou invalide (2FA)
- `isInvalidCredentials` : Email/mot de passe incorrect
- `isInvalidToken` : Token invalide ou expiré
- `isUserSuspended` : Utilisateur suspendu
- `hasErrorCode(DirectusErrorCode)` : Vérifier un code spécifique

**Codes d'erreur courants** :
- `DirectusErrorCode.invalidCredentials` : Credentials invalides
- `DirectusErrorCode.invalidToken` : Token invalide
- `DirectusErrorCode.tokenExpired` : Token expiré
- `DirectusErrorCode.invalidOtp` : Code OTP invalide
- `DirectusErrorCode.userSuspended` : Utilisateur suspendu

### DirectusValidationException

Erreurs de validation des données.

```dart
try {
  await directus.items('articles').createOne({
    'title': '', // Titre requis
    'email': 'invalid-email', // Format invalide
  });
} on DirectusValidationException catch (e) {
  print('Erreur de validation: ${e.message}');
  print('Code erreur: ${e.errorCode}'); // INVALID_PAYLOAD, UNPROCESSABLE_CONTENT
  
  // Erreurs par champ (si disponibles)
  final fieldErrors = e.fieldErrors;
  if (fieldErrors != null) {
    for (final entry in fieldErrors.entries) {
      print('${entry.key}: ${entry.value.join(', ')}');
    }
  }
  // Output:
  // title: Le champ title est requis
  // email: Format email invalide
}
```

**Codes d'erreur courants** :
- `DirectusErrorCode.invalidPayload` : Données invalides
- `DirectusErrorCode.invalidQuery` : Requête invalide
- `DirectusErrorCode.unprocessableContent` : Contenu non traitable
- `DirectusErrorCode.containsNullValues` : Valeurs NULL
- `DirectusErrorCode.notNullViolation` : Violation NOT NULL
- `DirectusErrorCode.valueOutOfRange` : Valeur hors limites
- `DirectusErrorCode.valueTooLong` : Valeur trop longue

### DirectusPermissionException

Erreurs de permission (403).

```dart
try {
  await directus.items('admin_only_collection').readMany();
} on DirectusPermissionException catch (e) {
  print('Permission refusée: ${e.message}');
  print('Code: ${e.statusCode}'); // 403
  print('Code erreur: ${e.errorCode}'); // FORBIDDEN
}
```

### DirectusNotFoundException

Ressource non trouvée (404).

```dart
try {
  await directus.items('articles').readOne('non-existent-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé: ${e.message}');
  print('Code: ${e.statusCode}'); // 404
  print('Code erreur: ${e.errorCode}'); // ROUTE_NOT_FOUND
}
```

### DirectusServerException

Erreurs serveur (5xx).

```dart
try {
  await directus.items('articles').readMany();
} on DirectusServerException catch (e) {
  print('Erreur serveur: ${e.message}');
  print('Code: ${e.statusCode}'); // 500, 503
  print('Code erreur: ${e.errorCode}'); // INTERNAL_SERVER_ERROR, SERVICE_UNAVAILABLE
}
```

**Codes d'erreur courants** :
- `DirectusErrorCode.internal` : Erreur serveur interne
- `DirectusErrorCode.serviceUnavailable` : Service indisponible
- `DirectusErrorCode.outOfDate` : Version obsolète

### DirectusRateLimitException

Erreurs de limitation de taux (429).

```dart
try {
  // Trop de requêtes
  for (int i = 0; i < 1000; i++) {
    await directus.items('articles').readMany();
  }
} on DirectusRateLimitException catch (e) {
  print('Rate limit atteint: ${e.message}');
  print('Code: ${e.statusCode}'); // 429
  print('Code erreur: ${e.errorCode}'); // REQUESTS_EXCEEDED
}
```

**Codes d'erreur courants** :
- `DirectusErrorCode.requestsExceeded` : Trop de requêtes
- `DirectusErrorCode.limitExceeded` : Limite dépassée
- `DirectusErrorCode.emailLimitExceeded` : Limite d'emails dépassée

### DirectusNetworkException

Erreurs réseau (timeout, pas de connexion, etc.).

```dart
try {
  await directus.items('articles').readMany();
} on DirectusNetworkException catch (e) {
  print('Erreur réseau: ${e.message}');
  // Possible de réessayer
}
```

### DirectusFileException

Erreurs liées aux fichiers.

```dart
try {
  await directus.files.uploadFile(
    bytes: largefile, // Fichier trop gros
    filename: 'large.pdf',
  );
} on DirectusFileException catch (e) {
  print('Erreur fichier: ${e.message}');
  print('Code erreur: ${e.errorCode}'); // CONTENT_TOO_LARGE
}
```

**Codes d'erreur courants** :
- `DirectusErrorCode.contentTooLarge` : Contenu trop large
- `DirectusErrorCode.unsupportedMediaType` : Type média non supporté
- `DirectusErrorCode.illegalAssetTransformation` : Transformation d'asset illégale

### DirectusDatabaseException

Erreurs de base de données.

```dart
try {
  await directus.items('articles').createOne({
    'title': 'Duplicate',
    'slug': 'existing-slug', // Slug unique déjà existant
  });
} on DirectusDatabaseException catch (e) {
  print('Erreur BD: ${e.message}');
  print('Collection: ${e.collection}');
  print('Champ: ${e.field}');
  print('Code erreur: ${e.errorCode}'); // RECORD_NOT_UNIQUE
}
```

**Codes d'erreur courants** :
- `DirectusErrorCode.invalidForeignKey` : Clé étrangère invalide
- `DirectusErrorCode.recordNotUnique` : Enregistrement non unique

## 📋 DirectusErrorCode - Liste complète

### Authentification
```dart
DirectusErrorCode.invalidCredentials  // Credentials invalides
DirectusErrorCode.invalidToken        // Token invalide
DirectusErrorCode.tokenExpired        // Token expiré
DirectusErrorCode.invalidOtp          // OTP invalide (2FA)
DirectusErrorCode.userSuspended       // Utilisateur suspendu
```

### Validation
```dart
DirectusErrorCode.invalidPayload      // Payload invalide
DirectusErrorCode.invalidQuery        // Query invalide
DirectusErrorCode.unprocessableContent // Contenu non traitable
DirectusErrorCode.containsNullValues  // Valeurs NULL
DirectusErrorCode.notNullViolation    // Violation NOT NULL
DirectusErrorCode.valueOutOfRange     // Valeur hors limites
DirectusErrorCode.valueTooLong        // Valeur trop longue
```

### Permissions et ressources
```dart
DirectusErrorCode.forbidden           // Accès interdit
DirectusErrorCode.routeNotFound       // Route non trouvée
```

### Serveur
```dart
DirectusErrorCode.internal            // Erreur serveur interne
DirectusErrorCode.serviceUnavailable  // Service indisponible
DirectusErrorCode.outOfDate           // Version obsolète
```

### Rate limiting
```dart
DirectusErrorCode.requestsExceeded    // Trop de requêtes
DirectusErrorCode.limitExceeded       // Limite dépassée
DirectusErrorCode.emailLimitExceeded  // Limite d'emails dépassée
```

### Base de données
```dart
DirectusErrorCode.invalidForeignKey   // Clé étrangère invalide
DirectusErrorCode.recordNotUnique     // Enregistrement non unique
```

### Fichiers
```dart
DirectusErrorCode.contentTooLarge         // Contenu trop large
DirectusErrorCode.unsupportedMediaType    // Type média non supporté
DirectusErrorCode.illegalAssetTransformation // Transformation illégale
DirectusErrorCode.rangeNotSatisfiable     // Plage non satisfaisable
```

### Configuration
```dart
DirectusErrorCode.invalidIp              // IP invalide
DirectusErrorCode.invalidProvider        // Provider invalide
DirectusErrorCode.invalidProviderConfig  // Config provider invalide
DirectusErrorCode.methodNotAllowed       // Méthode non autorisée
```

## 🎯 Gestion des erreurs

### Pattern de base

```dart
try {
  final result = await directus.items('articles').readMany();
  // Traiter le résultat
} on DirectusAuthException catch (e) {
  // Erreur d'authentification
  if (e.isInvalidToken) {
    print('Token expiré, reconnexion nécessaire');
    navigateToLogin();
  } else if (e.isInvalidCredentials) {
    print('Identifiants incorrects');
  }
} on DirectusPermissionException catch (e) {
  // Permission refusée
  print('Accès non autorisé: ${e.message}');
} on DirectusValidationException catch (e) {
  // Erreur de validation
  print('Validation échouée:');
  e.fieldErrors?.forEach((field, errors) {
    print('  $field: ${errors.join(', ')}');
  });
} on DirectusNotFoundException catch (e) {
  // Ressource non trouvée
  print('Ressource introuvable: ${e.message}');
} on DirectusRateLimitException catch (e) {
  // Rate limit
  print('Trop de requêtes: ${e.message}');
} on DirectusServerException catch (e) {
  // Erreur serveur
  print('Erreur serveur: ${e.message}');
} on DirectusNetworkException catch (e) {
  // Erreur réseau
  print('Erreur réseau: ${e.message}');
  showRetryDialog();
} on DirectusException catch (e) {
  // Autres erreurs Directus
  print('Erreur Directus: ${e.message}');
  print('Code: ${e.errorCode}');
} catch (e) {
  // Erreurs inattendues
  print('Erreur inattendue: $e');
}
```

### Gestion simplifiée

```dart
Future<List<Article>?> getArticles() async {
  try {
    final result = await directus.items('articles').readMany();
    return result.data?.map((d) => Article(d)).toList();
  } on DirectusException catch (e) {
    print('Erreur lors du chargement: ${e.message}');
    return null;
  }
}
```

## 📝 Erreurs de validation

### Structure des erreurs de champ

```dart
try {
  await directus.users.createUser({
    'email': 'invalid',
    'password': '123', // Trop court
  });
} on DirectusValidationException catch (e) {
  print('Validation échouée:');
  
  // Map<String, List<String>>?
  final fieldErrors = e.fieldErrors;
  
  if (fieldErrors != null) {
    // Exemple:
    // {
    //   'email': ['Email invalide'],
    //   'password': ['Minimum 8 caractères'],
    // }
    
    for (final entry in fieldErrors.entries) {
      print('${entry.key}:');
      for (final error in entry.value) {
        print('  - $error');
      }
    }
  }
}
```

### Afficher dans un formulaire Flutter

```dart
class ArticleForm extends StatefulWidget {
  @override
  _ArticleFormState createState() => _ArticleFormState();
}

class _ArticleFormState extends State<ArticleForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, String> _fieldErrors = {};
  
  Future<void> _submit() async {
    setState(() => _fieldErrors.clear());
    
    try {
      await directus.items('articles').createOne({
        'title': _titleController.text,
        'content': _contentController.text,
      });
      
      Navigator.pop(context);
    } on DirectusValidationException catch (e) {
      setState(() {
        // Convertir List<String> en String
        final errors = e.fieldErrors;
        if (errors != null) {
          _fieldErrors = errors.map(
            (key, value) => MapEntry(key, value.join(', ')),
          );
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre',
              errorText: _fieldErrors['title'],
            ),
          ),
          TextFormField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Contenu',
              errorText: _fieldErrors['content'],
            ),
          ),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
}
```

## 🔄 Retry et fallback

### Retry automatique

```dart
Future<T?> retryOperation<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } on DirectusNetworkException catch (e) {
      if (attempt == maxAttempts) {
        print('Échec après $maxAttempts tentatives');
        rethrow;
      }
      print('Tentative $attempt échouée, réessai dans ${delay.inSeconds}s');
      await Future.delayed(delay);
    }
  }
  return null;
}

// Utilisation
final articles = await retryOperation(
  operation: () => directus.items('articles').readMany(),
);
```

### Fallback sur cache

```dart
class ArticleService {
  List<Article>? _cachedArticles;
  
  Future<List<Article>> getArticles({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedArticles != null) {
      return _cachedArticles!;
    }
    
    try {
      final result = await directus.items('articles').readMany();
      _cachedArticles = result.data?.map((d) => Article(d)).toList();
      return _cachedArticles!;
    } on DirectusException catch (e) {
      print('Erreur: ${e.message}');
      
      // Retourner le cache si disponible
      if (_cachedArticles != null) {
        print('Utilisation du cache');
        return _cachedArticles!;
      }
      
      rethrow;
    }
  }
}
```

## 🎨 Exemples pratiques

### Service avec gestion d'erreurs complète

```dart
class ProductService {
  final DirectusClient directus;
  
  ProductService(this.directus);
  
  Future<Result<List<Product>>> getProducts() async {
    try {
      final result = await directus.items('products').readMany(
        query: QueryParameters(
          filter: Filter.field('status').equals('published'),
        ),
      );
      
      final products = result.data
          ?.map((d) => Product(d))
          .toList() ?? [];
      
      return Result.success(products);
    } on DirectusAuthException catch (e) {
      return Result.failure('Non authentifié. Veuillez vous reconnecter.');
    } on DirectusNetworkException catch (e) {
      return Result.failure('Erreur réseau. Vérifiez votre connexion.');
    } on DirectusException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('Une erreur inattendue s\'est produite');
    }
  }
}

// Classe Result
class Result<T> {
  final T? data;
  final String? error;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
  
  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

// Utilisation
final result = await productService.getProducts();

if (result.isSuccess) {
  showProducts(result.data!);
} else {
  showError(result.error!);
}
```

### Gestion centralisée avec Provider

```dart
class ErrorHandler {
  void handleError(BuildContext context, dynamic error) {
    String message;
    
    if (error is DirectusAuthException) {
      message = 'Erreur d\'authentification. Veuillez vous reconnecter.';
      Navigator.pushNamed(context, '/login');
    } else if (error is DirectusValidationException) {
      message = 'Données invalides:\n';
      error.fieldErrors.forEach((field, errors) {
        message += '• $field: ${errors.join(', ')}\n';
      });
    } else if (error is DirectusNotFoundException) {
      message = 'Ressource introuvable';
    } else if (error is DirectusNetworkException) {
      message = 'Erreur réseau. Vérifiez votre connexion.';
    } else if (error is DirectusException) {
      message = error.message;
    } else {
      message = 'Une erreur inattendue s\'est produite';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Utilisation
try {
  await directus.items('articles').createOne(item: {...});
} catch (e) {
  errorHandler.handleError(context, e);
}
```

### Logging des erreurs

```dart
class ErrorLogger {
  void log(dynamic error, [StackTrace? stackTrace]) {
    if (error is DirectusException) {
      print('=== Directus Error ===');
      print('Type: ${error.runtimeType}');
      print('Message: ${error.message}');
      print('Code: ${error.code}');
      if (error.errors != null) {
        print('Errors: ${error.errors}');
      }
    } else {
      print('=== Unexpected Error ===');
      print('Error: $error');
    }
    
    if (stackTrace != null) {
      print('Stack trace:');
      print(stackTrace);
    }
    
    // Envoyer à un service de monitoring (ex: Sentry)
    // Sentry.captureException(error, stackTrace: stackTrace);
  }
}
```

## 💡 Bonnes pratiques

### 1. Toujours gérer les erreurs

❌ **À éviter** :
```dart
final articles = await directus.items('articles').readMany();
// Crash si erreur
```

✅ **Bon** :
```dart
try {
  final articles = await directus.items('articles').readMany();
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
}
```

### 2. Être spécifique dans les catches

✅ **Bon** :
```dart
try {
  // ...
} on DirectusAuthException catch (e) {
  // Rediriger vers login
} on DirectusValidationException catch (e) {
  // Afficher erreurs de validation
} on DirectusException catch (e) {
  // Autres erreurs Directus
}
```

❌ **À éviter** :
```dart
try {
  // ...
} catch (e) {
  // Trop général
}
```

### 3. Fournir du feedback utilisateur

```dart
try {
  await directus.items('articles').createOne(item: {...});
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Article créé')),
  );
} on DirectusException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ ${e.message}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### 4. Logger les erreurs

```dart
try {
  // ...
} on DirectusException catch (e, stackTrace) {
  errorLogger.log(e, stackTrace);
  rethrow;
}
```

### 5. Gérer les timeout

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    timeout: Duration(seconds: 30),
  ),
);

try {
  await directus.items('articles').readMany();
} on DirectusNetworkException catch (e) {
  if (e.message.contains('timeout')) {
    print('La requête a pris trop de temps');
  }
}
```

## 🔗 Prochaines étapes

- [**Advanced**](12-advanced.md) - Fonctionnalités avancées
- [**Services**](08-services.md) - Services disponibles

## 📚 Référence API

- [DirectusException](api-reference/exceptions.md)
- [DirectusAuthException](api-reference/exceptions.md#authexception)
- [DirectusValidationException](api-reference/exceptions.md#validationexception)
