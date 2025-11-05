# Refresh Automatique des Tokens

Ce document explique le fonctionnement du refresh automatique des tokens d'authentification dans `fcs_directus`.

## Vue d'ensemble

Lorsque vous êtes authentifié avec Directus, vous recevez deux tokens :
- **Access Token** : Token de courte durée (ex: 15 minutes) utilisé pour authentifier les requêtes
- **Refresh Token** : Token de longue durée (ex: 7 jours) utilisé pour obtenir de nouveaux access tokens

Le **refresh automatique** permet au client de gérer automatiquement l'expiration des access tokens sans intervention de votre part.

## Fonctionnement

### Flux normal (token valide)

```
Client → DirectusHttpClient → Directus API → Réponse
                ↓
         Ajoute "Authorization: Bearer <token>"
```

### Flux avec refresh automatique (token expiré)

```
Client → DirectusHttpClient → Directus API
                ↓                     ↓
         Ajoute header      Erreur 401 TOKEN_EXPIRED
                                      ↓
                              Intercepteur onError
                                      ↓
                              Détecte TOKEN_EXPIRED
                                      ↓
                           Appelle /auth/refresh
                                      ↓
                          Nouveau access token
                                      ↓
                            Retry la requête
                                      ↓
                              Succès → Client
```

## Implémentation technique

### 1. Détection de l'erreur

L'intercepteur `onError` de Dio détecte les erreurs `TOKEN_EXPIRED` :

```dart
onError: (error, handler) async {
  final directusError = _handleError(error);
  
  if (directusError is DirectusAuthException &&
      directusError.errorCode == 'TOKEN_EXPIRED' &&
      _refreshToken != null) {
    // Déclencher le refresh automatique
  }
}
```

### 2. Rafraîchissement du token

La méthode `_refreshAccessToken()` gère le refresh de manière thread-safe :

```dart
Future<void> _refreshAccessToken() async {
  // Si un refresh est déjà en cours, attendre
  if (_refreshFuture != null) {
    return _refreshFuture!;
  }

  // Démarrer un nouveau refresh
  _refreshFuture = _performRefresh();
  
  try {
    await _refreshFuture!;
  } finally {
    _refreshFuture = null;
  }
}
```

### 3. Retry de la requête

Après le refresh, la requête originale est rejouée :

```dart
// Mettre à jour le header avec le nouveau token
final opts = error.requestOptions;
opts.headers['Authorization'] = 'Bearer $_accessToken';

// Rejouer la requête
final response = await _dio.fetch(opts);
return handler.resolve(response);
```

## Protections

### 1. Requêtes parallèles

Si plusieurs requêtes expirent simultanément, **un seul refresh** est effectué :

```dart
Future<void>? _refreshFuture;

if (_refreshFuture != null) {
  // Un refresh est déjà en cours, attendre
  return _refreshFuture!;
}
```

**Exemple :**
```dart
// 3 requêtes en parallèle
await Future.wait([
  client.items('articles').readMany(),
  client.items('pages').readMany(),
  client.items('users').readMany(),
]);

// Si le token expire :
// → Toutes les 3 reçoivent TOKEN_EXPIRED
// → Un seul refresh est effectué
// → Les 3 requêtes sont rejouées avec le nouveau token
```

### 2. Boucles infinies

Pour éviter les boucles de retry infinies :

```dart
final Set<String> _retryingRequests = {};

if (_retryingRequests.contains(requestId)) {
  // Cette requête a déjà été retryée, échouer
  return handler.next(error);
}

_retryingRequests.add(requestId);
```

**Scénario évité :**
1. Requête A échoue avec TOKEN_EXPIRED
2. Refresh échoue (refresh token invalide)
3. Retry de A → échoue encore
4. ❌ Sans protection : boucle infinie
5. ✅ Avec protection : erreur propagée au client

### 3. Isolation du refresh

L'appel `/auth/refresh` **n'utilise pas les intercepteurs** pour éviter une boucle :

```dart
final response = await _dio.post<Map<String, dynamic>>(
  '/auth/refresh',
  options: Options(
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);
```

Sans cette isolation, si le refresh échoue avec TOKEN_EXPIRED, l'intercepteur tenterait de rafraîchir... infiniment.

## Utilisation

### Code simplifié

**Avant (sans refresh automatique) :**
```dart
try {
  final articles = await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.errorCode == 'TOKEN_EXPIRED') {
    // Rafraîchir manuellement
    await client.auth.refresh();
    
    // Réessayer
    final articles = await client.items('articles').readMany();
  }
}
```

**Après (avec refresh automatique) :**
```dart
try {
  final articles = await client.items('articles').readMany();
  // Le refresh est automatique si nécessaire !
} on DirectusAuthException catch (e) {
  // On arrive ici uniquement si le refresh a échoué
  if (e.errorCode == 'TOKEN_EXPIRED') {
    print('Session expirée définitivement, reconnexion nécessaire');
  }
}
```

### Gestion d'erreur

Si vous recevez une `DirectusAuthException` avec `TOKEN_EXPIRED`, cela signifie que :
1. Le token d'accès a expiré
2. Le client a tenté de le rafraîchir
3. **Le refresh a échoué**

Causes possibles :
- Le refresh token a expiré (durée de vie écoulée)
- Le refresh token est invalide
- L'utilisateur a été déconnecté côté serveur
- Le refresh token a été révoqué

**Action recommandée :** Demander à l'utilisateur de se reconnecter.

```dart
try {
  await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.errorCode == 'TOKEN_EXPIRED') {
    // Rediriger vers la page de login
    Navigator.pushReplacementNamed(context, '/login');
    
    // Ou afficher un message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session expirée'),
        content: Text('Veuillez vous reconnecter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }
}
```

## Logs

Activez les logs pour voir le refresh en action :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    enableLogging: true, // ← Active les logs
  ),
);
```

**Exemple de logs :**
```
INFO: → GET https://directus.example.com/items/articles
SEVERE: ✗ https://directus.example.com/items/articles
INFO: Refreshing access token...
INFO: → POST https://directus.example.com/auth/refresh
INFO: ← 200 https://directus.example.com/auth/refresh
INFO: Access token refreshed successfully
INFO: Retrying request after token refresh: https://directus.example.com/items/articles
INFO: → GET https://directus.example.com/items/articles
INFO: ← 200 https://directus.example.com/items/articles
```

## Performances

### Impact minimal

Le refresh automatique n'a **aucun impact** sur les performances normales :
- Aucune vérification proactive de l'expiration
- Aucun timer ou polling
- Le refresh n'est déclenché que quand Directus retourne TOKEN_EXPIRED

### Requêtes parallèles optimisées

Grâce au Future partagé, plusieurs requêtes expirant simultanément ne causent qu'**un seul refresh** :

```dart
// 10 requêtes en parallèle
final futures = List.generate(
  10,
  (i) => client.items('collection$i').readMany(),
);

await Future.wait(futures);

// Si le token expire :
// → 10 erreurs TOKEN_EXPIRED
// → 1 seul appel à /auth/refresh
// → 10 requêtes rejouées
```

## Cas particuliers

### 1. Pas de refresh token

Si vous vous connectez sans recevoir de refresh token (rare) :

```dart
final authResponse = await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);

if (authResponse.refreshToken == null) {
  print('⚠️  Pas de refresh token, l\'auto-refresh ne fonctionnera pas');
}
```

Dans ce cas, le refresh automatique est **désactivé** et vous recevrez directement l'erreur TOKEN_EXPIRED.

### 2. Token statique

Si vous utilisez un token statique (pas d'authentification email/password) :

```dart
await client.auth.loginWithToken('my-static-token');
```

Il n'y a **pas de refresh token**, donc pas de refresh automatique possible. Les tokens statiques ne peuvent pas être rafraîchis.

### 3. Mode Session/Cookie

En mode `session` ou `cookie`, les tokens sont gérés par des cookies HTTP :

```dart
await client.auth.login(
  email: 'user@example.com',
  password: 'password',
  mode: AuthMode.session,
);
```

Le refresh automatique fonctionne également, mais les nouveaux tokens sont stockés dans les cookies par le navigateur.

## Désactivation

Le refresh automatique est **toujours actif** et ne peut pas être désactivé. C'est un comportement par défaut de la librairie.

Si vous voulez gérer manuellement le refresh, vous pouvez :

1. Intercepter l'erreur avant le retry
2. Utiliser directement `client.auth.refresh()`

```dart
try {
  await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  if (e.errorCode == 'TOKEN_EXPIRED') {
    // Gérer manuellement
    print('Token expiré, je gère moi-même');
    await client.auth.refresh();
    // Puis retry
  }
}
```

## Notification lors du Refresh

### Callback onTokenRefreshed

Vous pouvez être notifié automatiquement lorsque les tokens sont rafraîchis :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    // Callback appelé après chaque refresh automatique
    onTokenRefreshed: (accessToken, refreshToken) async {
      print('🔔 Tokens rafraîchis !');
      // Sauvegarder les nouveaux tokens
      await storage.saveAccessToken(accessToken);
      if (refreshToken != null) {
        await storage.saveRefreshToken(refreshToken);
      }
    },
  ),
);
```

### Utilisation avec storage persistant

#### Avec SharedPreferences

```dart
import 'package:shared_preferences/shared_preferences.dart';

final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
      }
    },
  ),
);
```

#### Avec FlutterSecureStorage (recommandé)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
    },
  ),
);
```

### Workflow complet avec persistance

```dart
// 1. Login initial
final auth = await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);

// Sauvegarder manuellement les tokens initiaux
await storage.write(key: 'access_token', value: auth.accessToken);
await storage.write(key: 'refresh_token', value: auth.refreshToken!);

// 2. Utiliser normalement
await client.items('articles').readMany();

// 3. Si le token expire pendant l'utilisation
// → Refresh automatique
// → onTokenRefreshed appelé automatiquement
// → Nouveaux tokens sauvegardés automatiquement

// 4. Au redémarrage de l'app
final savedRefreshToken = await storage.read(key: 'refresh_token');
if (savedRefreshToken != null) {
  await client.auth.restoreSession(savedRefreshToken);
  // Les nouveaux tokens sont automatiquement sauvegardés via le callback
}
```

### Gestion d'erreur dans le callback

**Important :** Les erreurs dans le callback ne bloquent pas le refresh :

```dart
onTokenRefreshed: (accessToken, refreshToken) async {
  try {
    await storage.saveTokens(accessToken, refreshToken);
  } catch (e) {
    // L'erreur est loggée mais ne bloque pas le refresh
    print('Erreur lors de la sauvegarde : $e');
  }
},
```

Le client gère automatiquement les erreurs du callback avec un `try-catch`.

## Tests

Pour tester le refresh automatique :

### 1. Simuler l'expiration

Utilisez un access token avec une durée très courte (ex: 10 secondes) :

```dart
// Dans la configuration Directus (serveur)
ACCESS_TOKEN_TTL="10s"
```

Puis attendez 10 secondes et effectuez une requête :

```dart
await client.auth.login(email: 'user@example.com', password: 'password');
print('Connecté, attente de 15 secondes...');
await Future.delayed(Duration(seconds: 15));
print('Requête...');
await client.items('articles').readMany(); // ← Devrait déclencher refresh
print('Succès !');
```

### 2. Tester le callback

```dart
int refreshCount = 0;

final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      refreshCount++;
      print('Refresh #$refreshCount détecté !');
    },
  ),
);

// Faire expirer le token et effectuer une requête
// Le callback devrait être appelé
```

### 3. Test de charge

Testez avec de nombreuses requêtes parallèles :

```dart
final futures = List.generate(
  100,
  (i) => client.items('articles').readMany(
    query: QueryParameters(limit: 1, offset: i),
  ),
);

// Si le token expire, un seul refresh pour toutes
// Le callback est appelé une seule fois
await Future.wait(futures);
```

## Résumé

| Aspect | Comportement |
|--------|-------------|
| **Activation** | Automatique, toujours actif |
| **Déclenchement** | Sur erreur `TOKEN_EXPIRED` |
| **Requêtes parallèles** | Un seul refresh pour toutes |
| **Protection boucle** | Oui, max 1 retry par requête |
| **Impact performances** | Aucun (uniquement sur expiration) |
| **Logs** | Disponibles avec `enableLogging: true` |
| **Notification** | Via callback `onTokenRefreshed` (optionnel) |
| **Persistance** | Possible via callback + storage |
| **Désactivation** | Non possible |
| **Thread-safe** | Oui |
| **Gestion d'erreur callback** | Erreurs loggées, ne bloquent pas le refresh |

## Bonnes pratiques

### 1. Toujours utiliser onTokenRefreshed

```dart
✅ BON
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    onTokenRefreshed: (accessToken, refreshToken) async {
      await storage.saveTokens(accessToken, refreshToken);
    },
  ),
);

❌ MAUVAIS (pas de persistance)
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://directus.example.com',
    // Pas de callback = tokens non sauvegardés
  ),
);
```

### 2. Utiliser un storage sécurisé

```dart
✅ BON
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final storage = FlutterSecureStorage();

❌ MAUVAIS
// SharedPreferences sans chiffrement pour tokens sensibles
```

### 3. Sauvegarder uniquement le refresh token

```dart
✅ BON (refresh token persisté)
await storage.write(key: 'refresh_token', value: refreshToken);
// Au redémarrage :
final token = await storage.read(key: 'refresh_token');
await client.auth.restoreSession(token);

❌ MAUVAIS (access token expire vite)
await storage.write(key: 'access_token', value: accessToken);
// Au redémarrage : probablement expiré
```

### 4. Gérer les erreurs du callback

```dart
✅ BON
onTokenRefreshed: (accessToken, refreshToken) async {
  try {
    await storage.saveTokens(accessToken, refreshToken);
  } catch (e) {
    logger.error('Erreur sauvegarde tokens', e);
  }
},

❌ MAUVAIS (pas de gestion d'erreur)
onTokenRefreshed: (accessToken, refreshToken) async {
  await storage.saveTokens(accessToken, refreshToken); // Peut throw
},
```

### 5. Tester le workflow complet

```dart
// Test complet :
// 1. Login → Sauvegarde tokens
await client.auth.login(email: 'user@example.com', password: 'pass');
await storage.saveRefreshToken(auth.refreshToken!);

// 2. Utilisation → Refresh automatique si nécessaire
await client.items('articles').readMany();

// 3. Fermeture app
await client.dispose();

// 4. Redémarrage → Restauration
final token = await storage.loadRefreshToken();
await client.auth.restoreSession(token);

// 5. Continuer normalement
await client.items('articles').readMany(); // ✅ Fonctionne
```

---

**Voir aussi :**
- [Documentation authentification complète](./AUTHENTICATION_AND_REQUESTS.md)
- [Exemple de base](../example/example_auto_refresh.dart)
- [Exemple avec callback et persistance](../example/example_token_refresh_callback.dart)
- [Types de tokens](../example/example_token_types.dart)
- [Gestion des erreurs](./11-error-handling.md)
