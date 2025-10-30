# Error Handling

Guide complet de la gestion des erreurs dans fcs_directus.

## 🚨 Types d'exceptions

fcs_directus fournit une hiérarchie d'exceptions pour gérer tous les cas d'erreur.

### DirectusException (Base)

Exception de base pour toutes les erreurs Directus.

```dart
class DirectusException implements Exception {
  final String message;
  final int? code;
  final Map<String, dynamic>? errors;
  
  // ...
}
```

### DirectusAuthException

Erreurs d'authentification et d'autorisation.

```dart
try {
  await directus.auth.login(email: 'wrong@email.com', password: 'wrong');
} on DirectusAuthException catch (e) {
  print('Erreur auth: ${e.message}');
  print('Code: ${e.code}'); // 401, 403, etc.
}
```

**Codes courants** :
- `401` : Non authentifié (credentials invalides)
- `403` : Non autorisé (permissions insuffisantes)
- `invalid_otp` : Code OTP invalide

### DirectusValidationException

Erreurs de validation des données.

```dart
try {
  await directus.items('articles').createOne(item: {
    'title': '', // Titre requis
    'email': 'invalid-email', // Format invalide
  });
} on DirectusValidationException catch (e) {
  print('Erreur de validation: ${e.message}');
  
  // Erreurs par champ
  for (final entry in e.fieldErrors.entries) {
    print('${entry.key}: ${entry.value.join(', ')}');
  }
  // Output:
  // title: Le champ title est requis
  // email: Format email invalide
}
```

### DirectusNotFoundException

Ressource non trouvée.

```dart
try {
  await directus.items('articles').readOne(id: 'non-existent-id');
} on DirectusNotFoundException catch (e) {
  print('Article non trouvé: ${e.message}');
  print('Code: ${e.code}'); // 404
}
```

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

## 🎯 Gestion des erreurs

### Pattern de base

```dart
try {
  final result = await directus.items('articles').readMany();
  // Traiter le résultat
} on DirectusAuthException catch (e) {
  // Erreur d'authentification
  print('Non authentifié: ${e.message}');
  navigateToLogin();
} on DirectusValidationException catch (e) {
  // Erreur de validation
  print('Validation échouée:');
  e.fieldErrors.forEach((field, errors) {
    print('  $field: ${errors.join(', ')}');
  });
} on DirectusNotFoundException catch (e) {
  // Ressource non trouvée
  print('Ressource introuvable: ${e.message}');
} on DirectusNetworkException catch (e) {
  // Erreur réseau
  print('Erreur réseau: ${e.message}');
  showRetryDialog();
} on DirectusException catch (e) {
  // Autres erreurs Directus
  print('Erreur: ${e.message}');
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
  await directus.users.createOne(item: {
    'email': 'invalid',
    'password': '123', // Trop court
  });
} on DirectusValidationException catch (e) {
  print('Validation échouée:');
  
  // Map<String, List<String>>
  final fieldErrors = e.fieldErrors;
  
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
      await directus.items('articles').createOne(item: {
        'title': _titleController.text,
        'content': _contentController.text,
      });
      
      Navigator.pop(context);
    } on DirectusValidationException catch (e) {
      setState(() {
        // Convertir List<String> en String
        _fieldErrors = e.fieldErrors.map(
          (key, value) => MapEntry(key, value.join(', ')),
        );
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
