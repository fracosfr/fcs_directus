# Résolution : Erreur 404 sur /auth/refresh

## 🐛 Symptôme

```
SEVERE: Token refresh failed - Status: 404
Message: This exception was thrown because the response has a status code of 404
```

L'endpoint `/auth/refresh` retourne une erreur 404 Not Found lors du refresh automatique des tokens.

## 🔍 Cause

Le problème était que lors du refresh du token, un **Dio temporaire** était créé sans reprendre les **headers personnalisés** de la configuration.

### Code problématique (avant)

```dart
final tempDio = Dio(
  BaseOptions(
    baseUrl: _config.baseUrl,
    connectTimeout: _config.timeout,
    receiveTimeout: _config.timeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // ❌ Manque les headers personnalisés de _config.headers
    },
  ),
);
```

## ✅ Solution appliquée

Les headers personnalisés sont maintenant inclus dans le Dio temporaire utilisé pour le refresh :

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

## 🎯 Cas d'usage typiques

### 1. Reverse proxy avec headers spécifiques

Si votre Directus est derrière un reverse proxy (nginx, Apache, etc.) qui nécessite des headers spécifiques :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://api.example.com',
    headers: {
      'X-Forwarded-Host': 'api.example.com',
      'X-Original-URL': '/directus',
      // Ces headers seront maintenant inclus dans le refresh
    },
  ),
);
```

### 2. API Gateway avec authentification

Si vous passez par une API Gateway qui nécessite une clé API :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://gateway.example.com',
    headers: {
      'X-API-Key': 'your-gateway-api-key',
      'X-Client-Id': 'your-client-id',
      // Ces headers seront inclus dans toutes les requêtes, y compris le refresh
    },
  ),
);
```

### 3. Headers de routing personnalisés

Si votre infrastructure utilise des headers pour router les requêtes :

```dart
final client = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://api.example.com',
    headers: {
      'X-Tenant-ID': 'tenant-123',
      'X-Environment': 'production',
      // Maintenant inclus dans le refresh
    },
  ),
);
```

## 🔧 Diagnostic

Si vous rencontrez toujours une erreur 404 après cette correction, vérifiez :

### 1. Configuration nginx/reverse proxy

Assurez-vous que le routing vers `/auth/refresh` est correctement configuré :

```nginx
location /auth/ {
    proxy_pass http://directus:8055/auth/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### 2. Version de Directus

L'endpoint `/auth/refresh` existe depuis Directus v9. Vérifiez votre version :

```bash
curl https://api.example.com/server/info
```

### 3. Test manuel

Testez l'endpoint manuellement avec curl :

```bash
curl -X POST https://api.example.com/auth/refresh \
  -H "Content-Type: application/json" \
  -H "Your-Custom-Header: value" \
  -d '{"refresh_token":"your-refresh-token","mode":"json"}'
```

### 4. Logs du serveur

Vérifiez les logs nginx/Apache pour voir si la requête arrive au serveur :

```bash
# Nginx
tail -f /var/log/nginx/access.log

# Apache
tail -f /var/log/apache2/access.log

# Docker
docker logs -f your-nginx-container
```

## 📝 Exemple complet

```dart
import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  // Configuration avec headers personnalisés
  final client = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://api.blue.fracos.fr',
      headers: {
        // Headers personnalisés qui seront maintenant inclus
        // dans TOUTES les requêtes, y compris le refresh
        'X-Custom-Header': 'value',
        'X-Client-Version': '1.0.0',
      },
      enableLogging: true,
      onTokenRefreshed: (accessToken, refreshToken) async {
        print('Tokens refreshed successfully!');
        print('New access token: ${accessToken.substring(0, 20)}...');
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
    final items = await client.items('your_collection').readMany();
    
    // Le refresh se fera automatiquement avec les headers personnalisés
    // si le token expire pendant l'utilisation
    
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.dispose();
  }
}
```

## 🎉 Résultat

Après cette correction :
- ✅ Les headers personnalisés sont inclus dans le refresh
- ✅ Les reverse proxies fonctionnent correctement
- ✅ Les API Gateways sont supportées
- ✅ Le refresh automatique fonctionne même avec des configurations complexes

## 📚 Références

- [Documentation Directus - Authentication](https://docs.directus.io/reference/authentication.html)
- [Documentation Directus - Refresh Token](https://docs.directus.io/reference/authentication.html#refresh-token)
- Code source : `lib/src/core/directus_http_client.dart` ligne ~210
