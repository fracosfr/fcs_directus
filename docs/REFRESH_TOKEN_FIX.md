# Corrections du mécanisme de refresh token

## Problème identifié

L'application rencontrait une boucle infinie lors du rafraîchissement des tokens :
```
INFO: Token refresh already in progress, waiting...
SEVERE: ✗ https://api.blue.fracos.fr/auth/refresh
INFO: Token refresh already in progress, waiting...
```

Le refresh échouait mais les requêtes en attente tentaient de relancer un nouveau refresh, créant une boucle.

## Causes racines

1. **Le refresh utilisait le même client Dio avec intercepteurs** : Quand `/auth/refresh` échouait, l'intercepteur d'erreur pouvait tenter de le retry, créant une récursion
2. **Mauvaise propagation des erreurs** : Quand un refresh échouait, les requêtes en attente ne recevaient pas correctement l'erreur
3. **Absence de nettoyage des tokens invalides** : Les tokens invalides/expirés n'étaient pas supprimés en cas d'échec de refresh

## Solutions implémentées

### 1. Dio temporaire pour le refresh (`directus_http_client.dart`)

Créer une instance Dio dédiée SANS intercepteurs pour `/auth/refresh` :

```dart
Future<void> _performRefresh() async {
  // Créer un Dio temporaire sans intercepteurs pour éviter les boucles
  final tempDio = Dio(
    BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: _config.timeout,
      receiveTimeout: _config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final response = await tempDio.post<Map<String, dynamic>>(
    '/auth/refresh',
    data: {'refresh_token': _refreshToken, 'mode': 'json'},
  );
  // ...
}
```

### 2. Meilleure gestion des erreurs

Amélioration de la propagation d'erreur dans `_refreshAccessToken` :

```dart
Future<void> _refreshAccessToken() async {
  if (_refreshFuture != null) {
    _logger.info('Token refresh already in progress, waiting...');
    try {
      await _refreshFuture!;
      return; // Succès
    } catch (e) {
      // Propager l'erreur du refresh
      rethrow;
    }
  }

  _refreshFuture = _performRefresh();
  try {
    await _refreshFuture!;
    _refreshFuture = null; // Nettoyer en cas de succès
  } catch (e) {
    _refreshFuture = null; // Nettoyer en cas d'erreur
    rethrow; // Propager l'erreur
  }
}
```

### 3. Nettoyage automatique des tokens invalides

Si le refresh échoue avec 401/403, supprimer les tokens :

```dart
on DioException catch (e) {
  _logger.severe(
    'Token refresh failed - Status: ${e.response?.statusCode}, '
    'Message: ${e.message}, '
    'Response: ${e.response?.data}'
  );
  
  // Si le refresh token est invalide/expiré, le supprimer
  if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
    _logger.warning('Refresh token is invalid or expired, clearing all tokens');
    _accessToken = null;
    _refreshToken = null;
  }
  
  throw DirectusAuthException(
    message: errorMessage,
    errorCode: 'TOKEN_REFRESH_FAILED',
    statusCode: e.response?.statusCode,
  );
}
```

### 4. Nouvelles méthodes publiques

#### `DirectusClient.clearTokens()`

Permet de nettoyer les tokens quand nécessaire :

```dart
void clearTokens() {
  _httpClient.clearTokens();
}
```

#### `AuthService.setTokens()`

Permet de restaurer une session depuis le stockage :

```dart
void setTokens({String? accessToken, String? refreshToken}) {
  _httpClient.setTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
```

## Utilisation recommandée

### Configuration avec callback

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      // Sauvegarder les nouveaux tokens dans le stockage persistant
      await storage.saveTokens(accessToken, refreshToken);
    },
  ),
);
```

### Gestion des erreurs de refresh

```dart
try {
  final items = await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.errorCode == 'TOKEN_REFRESH_FAILED') {
    // Le refresh token est invalide/expiré
    client.clearTokens();
    await storage.clearTokens();
    // Rediriger vers la page de login
  }
}
```

### Restauration de session

```dart
// Au démarrage de l'app
final savedTokens = await storage.loadTokens();
if (savedTokens != null) {
  client.auth.setTokens(
    accessToken: savedTokens['accessToken'],
    refreshToken: savedTokens['refreshToken'],
  );
  
  // Vérifier que la session est valide
  try {
    await client.users.me();
    print('Session restaurée');
  } on DirectusAuthException {
    // Session invalide
    client.clearTokens();
    await storage.clearTokens();
  }
}
```

## Fichiers modifiés

1. **lib/src/core/directus_http_client.dart**
   - Dio temporaire pour le refresh
   - Meilleure gestion des erreurs
   - Nettoyage automatique des tokens invalides
   - Ajout de `clearTokens()`

2. **lib/src/core/directus_client.dart**
   - Exposition de `clearTokens()`

3. **lib/src/services/auth_service.dart**
   - Ajout de `setTokens()`

4. **example/example_token_refresh_handling.dart** (nouveau)
   - Guide complet de gestion du refresh token
   - Exemples de configuration
   - Gestion d'erreur
   - Intégration avec stockage persistant

## Logs attendus après correction

### Scénario 1: Refresh réussi
```
INFO: Refreshing access token...
INFO: Access token refreshed successfully
INFO: Token refresh notification sent to application
INFO: Retrying request after token refresh
```

### Scénario 2: Refresh échoué (token invalide)
```
INFO: Refreshing access token...
SEVERE: Token refresh failed - Status: 401, Message: ...
WARNING: Refresh token is invalid or expired, clearing all tokens
```

### Scénario 3: Refresh en cours
```
INFO: Token refresh already in progress, waiting...
INFO: Access token refreshed successfully
INFO: Retrying request after token refresh
```

## Tests recommandés

1. **Test avec token expiré** : Vérifier que le refresh fonctionne automatiquement
2. **Test avec refresh token invalide** : Vérifier que l'erreur est bien propagée et les tokens nettoyés
3. **Test avec requêtes concurrentes** : Vérifier qu'un seul refresh est effectué
4. **Test de restauration de session** : Vérifier que les tokens sauvegardés fonctionnent

## Migration

Aucune modification breaking. Les applications existantes continuent de fonctionner.

Ajouts optionnels recommandés :
- Implémenter `onTokenRefreshed` dans `DirectusConfig`
- Gérer les erreurs `TOKEN_REFRESH_FAILED`
- Utiliser `clearTokens()` lors de la déconnexion
