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

### 2. Forcer un token invalide

```dart
// ⚠️ Ne pas utiliser en production !
final client = DirectusClient(config);
await client.auth.login(email: 'user@example.com', password: 'password');

// Forcer un token expiré pour tester
client._httpClient.setTokens(
  accessToken: 'expired_token',
  refreshToken: client.auth.refreshToken,
);

// La prochaine requête devrait déclencher le refresh
await client.items('articles').readMany();
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
| **Désactivation** | Non possible |
| **Thread-safe** | Oui |

---

**Voir aussi :**
- [Documentation authentification complète](./AUTHENTICATION_AND_REQUESTS.md)
- [Exemple complet](../example/example_auto_refresh.dart)
- [Gestion des erreurs](./11-error-handling.md)
