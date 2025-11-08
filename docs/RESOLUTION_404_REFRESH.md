# ✅ Résolution : Erreur 404 sur /auth/refresh

## 🎯 Problème identifié

Lors du refresh automatique du token, vous rencontriez une **erreur 404** sur l'endpoint `/auth/refresh` :

```
SEVERE: Token refresh failed - Status: 404
Message: This exception was thrown because the response has a status code of 404
```

## 🔍 Cause racine

Le code créait un **Dio temporaire** pour le refresh du token (afin d'éviter les boucles infinies avec les intercepteurs), mais ce Dio temporaire **ne reprenait pas les headers personnalisés** de `DirectusConfig.headers`.

Si votre infrastructure nécessite des headers spécifiques (reverse proxy, API Gateway, etc.), l'endpoint `/auth/refresh` retournait une 404 car la requête n'arrivait pas correctement au serveur Directus.

## ✅ Solution appliquée

### Avant (code problématique)

```dart
final tempDio = Dio(
  BaseOptions(
    baseUrl: _config.baseUrl,
    connectTimeout: _config.timeout,
    receiveTimeout: _config.timeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // ❌ Manque les headers personnalisés
    },
  ),
);
```

### Après (code corrigé)

```dart
// Combiner les headers de base avec les headers personnalisés
final refreshHeaders = <String, String>{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

// Ajouter les headers personnalisés de la configuration s'ils existent
if (_config.headers != null) {
  refreshHeaders.addAll(_config.headers!);
}

final tempDio = Dio(
  BaseOptions(
    baseUrl: _config.baseUrl,
    connectTimeout: _config.timeout,
    receiveTimeout: _config.timeout,
    headers: refreshHeaders, // ✅ Inclut les headers personnalisés
  ),
);
```

## 🎯 Comment l'utiliser

### Configuration avec headers personnalisés

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://api.blue.fracos.fr',
    headers: {
      // Vos headers personnalisés
      'X-Forwarded-Host': 'api.blue.fracos.fr',
      'X-Custom-Header': 'value',
      // Etc.
    },
    enableLogging: true,
  ),
);
```

### Ces headers seront maintenant inclus :

1. ✅ Dans toutes les requêtes normales (login, items, etc.)
2. ✅ **Dans le refresh automatique du token** (nouveau !)
3. ✅ Dans les retry après expiration du token

## 🔧 Cas d'usage typiques

### 1. Reverse Proxy (nginx, Apache)

Si Directus est derrière un reverse proxy :

```dart
DirectusConfig(
  baseUrl: 'https://api.example.com',
  headers: {
    'X-Forwarded-Host': 'api.example.com',
    'X-Forwarded-Proto': 'https',
  },
)
```

### 2. API Gateway

Si vous passez par une API Gateway :

```dart
DirectusConfig(
  baseUrl: 'https://gateway.example.com/directus',
  headers: {
    'X-API-Key': 'your-api-key',
    'X-Client-ID': 'your-client-id',
  },
)
```

### 3. Multi-tenant

Pour une application multi-tenant :

```dart
DirectusConfig(
  baseUrl: 'https://api.example.com',
  headers: {
    'X-Tenant-ID': 'tenant-123',
    'X-Environment': 'production',
  },
)
```

## 📊 Impact du changement

| Avant | Après |
|-------|-------|
| ❌ Headers manquants dans refresh | ✅ Headers inclus dans refresh |
| ❌ 404 sur /auth/refresh | ✅ Refresh fonctionne |
| ❌ Incompatible avec reverse proxy | ✅ Compatible reverse proxy |
| ❌ Incompatible avec API Gateway | ✅ Compatible API Gateway |

## 🧪 Tests

Tous les tests passent avec ce changement :

```bash
flutter test
# 00:01 +101 ~9: All tests passed!
```

## 📚 Documentation créée

1. **`docs/FIX_404_REFRESH_TOKEN.md`** - Guide complet de diagnostic et résolution
2. **`example/example_custom_headers.dart`** - 5 exemples d'utilisation
3. **`CHANGELOG.md`** - Entrée dans le changelog

## 🚀 Prochaines étapes

1. **Testez avec votre configuration** :
   - Ajoutez vos headers personnalisés dans `DirectusConfig.headers`
   - Vérifiez que le refresh fonctionne maintenant

2. **Si le problème persiste** :
   - Activez les logs : `enableLogging: true`
   - Vérifiez les logs de votre reverse proxy/gateway
   - Consultez `docs/FIX_404_REFRESH_TOKEN.md` pour le diagnostic

3. **Configuration nginx** (si applicable) :
   ```nginx
   location /auth/ {
       proxy_pass http://directus:8055/auth/;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```

## 💡 Exemple complet

```dart
import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.blue.fracos.fr',
      headers: {
        // Vos headers personnalisés seront maintenant
        // inclus dans le refresh automatique
        'X-Custom-Header': 'value',
      },
      enableLogging: true,
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('Token refreshed successfully!');
        // Sauvegarder les nouveaux tokens
      },
    ),
  );

  try {
    // Login
    await client.auth.login(
      email: 'user@example.com',
      password: 'password',
    );

    // Utiliser l'API
    final items = await client.items('brigade').readMany();
    
    // Le refresh se fera automatiquement avec vos headers
    // si le token expire
    
  } finally {
    await client.dispose();
  }
}
```

## ✅ Résumé

- ✅ **Problème** : 404 sur /auth/refresh
- ✅ **Cause** : Headers manquants dans le Dio temporaire
- ✅ **Solution** : Headers personnalisés maintenant inclus
- ✅ **Impact** : Compatible avec reverse proxy, API Gateway, multi-tenant
- ✅ **Tests** : Tous les tests passent
- ✅ **Documentation** : Complète avec exemples

Le refresh automatique du token devrait maintenant fonctionner correctement avec votre infrastructure ! 🎉
