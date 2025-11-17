# Callback onAuthError - Gestion des erreurs d'authentification

## Vue d'ensemble

Le callback `onAuthError` du `DirectusConfig` permet à votre application d'être informée automatiquement de **toutes les erreurs d'authentification** qui surviennent, notamment :

- ✅ **Échec de l'auto-refresh** du token (refresh token expiré/invalide)
- ✅ **Erreurs de login** (identifiants incorrects, compte suspendu, etc.)
- ✅ **Tokens invalides** ou expirés définitivement
- ✅ **Toutes les DirectusAuthException**

Ce mécanisme permet de **centraliser la gestion des erreurs d'authentification** et de réagir de manière appropriée (redirection vers login, message d'erreur, etc.).

---

## Configuration

### Syntaxe de base

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onAuthError: (exception) async {
      // Gérer l'erreur d'authentification
      print('Erreur auth: ${exception.errorCode}');
    },
  ),
);
```

### Signature du callback

```dart
Future<void> Function(DirectusAuthException exception)? onAuthError
```

**Paramètres** :
- `exception` : Une instance de `DirectusAuthException` contenant :
  - `errorCode` : Le code d'erreur Directus (ex: `TOKEN_REFRESH_FAILED`, `INVALID_CREDENTIALS`)
  - `message` : Le message d'erreur descriptif
  - `statusCode` : Le code HTTP (ex: 401, 403)
  - `extensions` : Données supplémentaires de l'erreur

---

## Cas d'utilisation

### 1. Redirection automatique vers le login

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onAuthError: (exception) async {
      // Vérifier si c'est une erreur de refresh
      if (exception.errorCode == 'TOKEN_REFRESH_FAILED' ||
          exception.errorCode == 'TOKEN_EXPIRED') {
        // Le refresh a échoué, l'utilisateur doit se reconnecter
        await storage.clearTokens();
        await navigateToLogin(); // Navigation Flutter
      }
    },
  ),
);
```

### 2. Gestion des différents types d'erreurs

```dart
DirectusConfig(
  baseUrl: 'https://directus.example.com',
  onAuthError: (exception) async {
    switch (exception.errorCode) {
      case 'TOKEN_REFRESH_FAILED':
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        // Session expirée définitivement
        await storage.clearTokens();
        await navigateToLogin();
        break;

      case 'INVALID_CREDENTIALS':
        // Mauvais identifiants lors du login
        showSnackBar('Identifiants incorrects');
        break;

      case 'USER_SUSPENDED':
        // Compte utilisateur suspendu
        showDialog('Votre compte a été suspendu. Contactez l\'administrateur.');
        break;

      case 'INVALID_OTP':
        // Code OTP invalide
        showSnackBar('Code de vérification invalide');
        break;

      default:
        // Erreur générique
        showSnackBar('Erreur d\'authentification: ${exception.message}');
    }
  },
)
```

### 3. Logging et analytics

```dart
DirectusConfig(
  baseUrl: 'https://directus.example.com',
  onAuthError: (exception) async {
    // Logger l'erreur
    logger.error(
      'Auth error: ${exception.errorCode}',
      error: exception,
      stackTrace: StackTrace.current,
    );

    // Envoyer à un service d'analytics
    analytics.logEvent(
      name: 'auth_error',
      parameters: {
        'error_code': exception.errorCode,
        'status_code': exception.statusCode,
      },
    );

    // Notifier l'utilisateur si nécessaire
    if (exception.errorCode == 'TOKEN_REFRESH_FAILED') {
      await navigateToLogin();
    }
  },
)
```

### 4. Intégration avec un système d'état (Bloc, Riverpod, etc.)

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  DirectusClient? _client;

  void initialize() {
    _client = DirectusClient(
      DirectusConfig(
        baseUrl: 'https://directus.example.com',
        onAuthError: (exception) async {
          // Émettre un événement pour changer l'état
          add(AuthErrorOccurred(exception));
        },
      ),
    );
  }
}

// Dans le Bloc
on<AuthErrorOccurred>((event, emit) {
  if (event.exception.errorCode == 'TOKEN_REFRESH_FAILED') {
    emit(AuthState.unauthenticated());
  }
});
```

### 5. Utilisation combinée avec onTokenRefreshed

```dart
DirectusConfig(
  baseUrl: 'https://directus.example.com',
  
  // ✅ Succès du refresh
  onTokenRefreshed: (accessToken, refreshToken) async {
    // Sauvegarder les nouveaux tokens
    await storage.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await storage.saveRefreshToken(refreshToken);
    }
    print('✅ Tokens rafraîchis et sauvegardés');
  },
  
  // ❌ Échec du refresh ou autre erreur d'auth
  onAuthError: (exception) async {
    // Nettoyer les tokens invalides
    await storage.clearTokens();
    
    if (exception.errorCode == 'TOKEN_REFRESH_FAILED') {
      print('❌ Refresh échoué, redirection vers login');
      await navigateToLogin();
    }
  },
)
```

---

## Codes d'erreur courants

Voici les codes d'erreur `DirectusAuthException` les plus fréquents :

| Code d'erreur | Description | Action recommandée |
|---------------|-------------|-------------------|
| `TOKEN_REFRESH_FAILED` | Le refresh du token a échoué (refresh token expiré) | Rediriger vers login |
| `TOKEN_EXPIRED` | Token d'accès expiré (normalement géré par auto-refresh) | Automatique ou rediriger |
| `INVALID_TOKEN` | Token invalide ou corrompu | Nettoyer et rediriger |
| `INVALID_CREDENTIALS` | Identifiants incorrects lors du login | Message d'erreur utilisateur |
| `INVALID_OTP` | Code OTP invalide | Demander de resaisir le code |
| `USER_SUSPENDED` | Compte utilisateur suspendu | Message informatif |

---

## Flux complet

### Scénario : Auto-refresh réussit

```
1. Requête API → Token expiré (401)
2. Intercepteur détecte TOKEN_EXPIRED
3. Auto-refresh du token
   └─> ✅ Succès
       └─> Callback onTokenRefreshed() appelé
       └─> Retry de la requête
       └─> ✅ Succès
```

**Résultat** : Transparent pour l'utilisateur, aucune intervention nécessaire.

### Scénario : Auto-refresh échoue

```
1. Requête API → Token expiré (401)
2. Intercepteur détecte TOKEN_EXPIRED
3. Auto-refresh du token
   └─> ❌ Échec (refresh token expiré)
       └─> Callback onAuthError() appelé avec TOKEN_REFRESH_FAILED
       └─> Application nettoie les tokens et redirige vers login
```

**Résultat** : L'utilisateur est informé et redirigé vers l'écran de connexion.

### Scénario : Erreur de login

```
1. Tentative de login avec mauvais identifiants
2. API retourne 401 INVALID_CREDENTIALS
3. Callback onAuthError() appelé avec INVALID_CREDENTIALS
4. Application affiche un message d'erreur à l'utilisateur
```

---

## Exemple complet (Application Flutter)

```dart
class DirectusService {
  late final DirectusClient client;
  final FlutterSecureStorage storage;
  final GlobalKey<NavigatorState> navigatorKey;

  DirectusService({
    required this.storage,
    required this.navigatorKey,
  }) {
    client = DirectusClient(
      DirectusConfig(
        baseUrl: 'https://directus.example.com',
        
        // Callback de succès
        onTokenRefreshed: (accessToken, refreshToken) async {
          await _saveTokens(accessToken, refreshToken);
          print('✅ Session prolongée automatiquement');
        },
        
        // Callback d'erreur
        onAuthError: (exception) async {
          await _handleAuthError(exception);
        },
      ),
    );
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> _handleAuthError(DirectusAuthException exception) async {
    print('❌ Erreur auth: ${exception.errorCode} - ${exception.message}');

    // Nettoyer les tokens
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    client.auth.clearTokens();

    // Logger l'erreur
    FirebaseCrashlytics.instance.recordError(
      exception,
      StackTrace.current,
      reason: 'Auth error: ${exception.errorCode}',
    );

    // Gérer selon le type d'erreur
    switch (exception.errorCode) {
      case 'TOKEN_REFRESH_FAILED':
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        // Session expirée, rediriger vers login
        _navigateToLogin();
        _showSnackBar('Votre session a expiré. Veuillez vous reconnecter.');
        break;

      case 'USER_SUSPENDED':
        _navigateToLogin();
        _showDialog(
          title: 'Compte suspendu',
          message: 'Votre compte a été suspendu. Veuillez contacter l\'administrateur.',
        );
        break;

      case 'INVALID_CREDENTIALS':
        _showSnackBar('Identifiants incorrects. Veuillez réessayer.');
        break;

      default:
        _showSnackBar('Erreur d\'authentification: ${exception.message}');
    }
  }

  void _navigateToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showDialog({required String title, required String message}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Restaurer la session au démarrage
  Future<bool> restoreSession() async {
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');

    if (accessToken == null || refreshToken == null) {
      return false;
    }

    try {
      await client.auth.restoreSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } on DirectusAuthException catch (e) {
      // Le callback onAuthError a déjà géré l'erreur
      print('Restore session failed: ${e.errorCode}');
      return false;
    }
  }
}
```

---

## Bonnes pratiques

### ✅ À faire

1. **Toujours nettoyer les tokens** en cas d'erreur définitive
   ```dart
   if (exception.errorCode == 'TOKEN_REFRESH_FAILED') {
     await storage.clearTokens();
     client.auth.clearTokens();
   }
   ```

2. **Logger les erreurs** pour le debugging
   ```dart
   logger.error('Auth error', error: exception);
   analytics.logEvent('auth_error', ...);
   ```

3. **Différencier les erreurs temporaires des erreurs définitives**
   - Temporaire : `INVALID_OTP`, `INVALID_CREDENTIALS` → Message d'erreur
   - Définitive : `TOKEN_REFRESH_FAILED`, `USER_SUSPENDED` → Déconnexion

4. **Utiliser avec onTokenRefreshed** pour une gestion complète
   ```dart
   onTokenRefreshed: (a, r) => saveTokens(a, r),  // ✅ Succès
   onAuthError: (e) => handleError(e),             // ❌ Échec
   ```

### ❌ À éviter

1. **Ne pas bloquer le callback** avec des opérations longues
   ```dart
   // ❌ Mauvais
   onAuthError: (e) async {
     await Future.delayed(Duration(seconds: 10)); // Trop long
   }
   ```

2. **Ne pas propager l'exception** dans le callback
   ```dart
   // ❌ Mauvais
   onAuthError: (e) async {
     throw Exception('Error'); // Ne pas throw
   }
   ```

3. **Ne pas ignorer les erreurs**
   ```dart
   // ❌ Mauvais
   onAuthError: (e) async {
     // Callback vide, aucune action
   }
   
   // ✅ Bon
   onAuthError: (e) async {
     logger.error('Auth error: ${e.errorCode}');
     // Au minimum logger l'erreur
   }
   ```

---

## Résumé

Le callback `onAuthError` est un outil puissant pour :

- ✅ **Centraliser** la gestion des erreurs d'authentification
- ✅ **Automatiser** la redirection vers le login en cas de session expirée
- ✅ **Améliorer** l'expérience utilisateur avec des messages appropriés
- ✅ **Simplifier** le code en évitant les try/catch répétés
- ✅ **Logger** et monitorer les problèmes d'authentification

**Utilisez-le en complément de `onTokenRefreshed`** pour une gestion complète et robuste de l'authentification dans votre application.
