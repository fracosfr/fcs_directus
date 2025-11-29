# Guide de démarrage

Ce guide vous accompagne dans l'installation et la configuration de la librairie fcs_directus.

## Prérequis

- **Dart SDK** : 3.0 ou supérieur
- **Flutter** : 3.0 ou supérieur (pour les applications Flutter)
- **Serveur Directus** : v11.1.0 ou supérieur (recommandé)

## Installation

Ajoutez la dépendance dans votre fichier `pubspec.yaml` :

```yaml
dependencies:
  fcs_directus: ^2.0.0
```

Exécutez la commande suivante pour installer les dépendances :

```bash
# Pour Flutter
flutter pub get

# Pour Dart pur
dart pub get
```

## Configuration de base

### Créer le client

```dart
import 'package:fcs_directus/fcs_directus.dart';

void main() async {
  // Configuration minimale
  final config = DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  );
  
  // Créer le client
  final client = DirectusClient(config);
  
  // Le client est prêt à être utilisé !
}
```

### Options de configuration

La classe `DirectusConfig` accepte plusieurs paramètres :

```dart
final config = DirectusConfig(
  // URL de base du serveur Directus (obligatoire)
  baseUrl: 'https://your-directus-instance.com',
  
  // Timeout des requêtes HTTP (défaut: 30 secondes)
  timeout: Duration(seconds: 30),
  
  // Headers personnalisés ajoutés à toutes les requêtes
  headers: {
    'X-Custom-Header': 'value',
  },
  
  // User-Agent personnalisé
  customUserAgent: 'MyApp/1.0.0',
  
  // Activer les logs de debug
  enableLogging: true,
  
  // Callback appelé après chaque refresh de token réussi
  onTokenRefreshed: (accessToken, refreshToken) async {
    print('Nouveaux tokens reçus');
  },
  
  // Callback appelé en cas d'erreur d'authentification
  onAuthError: (exception) async {
    print('Erreur auth: ${exception.message}');
  },
);
```

## Authentification

### Login avec email et mot de passe

```dart
try {
  final response = await client.auth.login(
    email: 'user@example.com',
    password: 'your-password',
  );
  
  print('Connecté !');
  print('Access Token: ${response.accessToken}');
  print('Expire dans: ${response.expiresIn} secondes');
  
  // Si 2FA activé
  if (response.refreshToken != null) {
    print('Refresh Token: ${response.refreshToken}');
  }
} on DirectusAuthException catch (e) {
  if (e.isOtpRequired) {
    // Demander le code OTP à l'utilisateur
    print('Code 2FA requis');
  } else if (e.isInvalidCredentials) {
    print('Identifiants incorrects');
  } else {
    print('Erreur: ${e.message}');
  }
}
```

### Login avec 2FA (TOTP)

```dart
final response = await client.auth.login(
  email: 'user@example.com',
  password: 'your-password',
  otp: '123456', // Code TOTP de l'app d'authentification
);
```

### Login avec token statique

Pour les applications backend ou les scripts :

```dart
await client.auth.loginWithToken('votre-token-statique-directus');
```

### Déconnexion

```dart
await client.auth.logout();
```

### Rafraîchir le token manuellement

```dart
await client.auth.refresh();
```

> **Note** : Le client gère automatiquement le refresh des tokens expirés. Cette méthode n'est utile que si vous voulez forcer un refresh.

## Première requête

Une fois authentifié, vous pouvez effectuer des requêtes :

```dart
// Lire tous les articles
final articles = await client.items('articles').readMany();

print('${articles.data.length} articles trouvés');

for (final article in articles.data) {
  print('- ${article['title']}');
}
```

## Structure du projet recommandée

Pour une application Flutter, nous recommandons cette structure :

```
lib/
  main.dart
  directus/
    client.dart          # Singleton du client
    models/
      article.dart       # Modèle Article
      user.dart          # Modèle User
    services/
      article_service.dart
```

### Singleton du client (exemple)

```dart
// lib/directus/client.dart
import 'package:fcs_directus/fcs_directus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DirectusService {
  static DirectusClient? _client;
  static final _storage = FlutterSecureStorage();
  
  static DirectusClient get client {
    _client ??= DirectusClient(
      DirectusConfig(
        baseUrl: 'https://your-directus-instance.com',
        onTokenRefreshed: (accessToken, refreshToken) async {
          await _storage.write(key: 'access_token', value: accessToken);
          if (refreshToken != null) {
            await _storage.write(key: 'refresh_token', value: refreshToken);
          }
        },
        onAuthError: (exception) async {
          await _storage.deleteAll();
          // Naviguer vers la page de login
        },
      ),
    );
    return _client!;
  }
  
  static Future<bool> restoreSession() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await client.auth.restoreSession(refreshToken);
        return true;
      } catch (e) {
        await _storage.deleteAll();
      }
    }
    return false;
  }
  
  static void dispose() {
    _client?.dispose();
    _client = null;
  }
}
```

## Prochaines étapes

- [02-authentication.md](02-authentication.md) - Guide complet de l'authentification
- [03-crud-operations.md](03-crud-operations.md) - Opérations CRUD sur les items
- [04-custom-models.md](04-custom-models.md) - Créer des modèles personnalisés
- [05-filters.md](05-filters.md) - Système de filtres type-safe
- [06-deep-queries.md](06-deep-queries.md) - Charger les relations
- [07-aggregations.md](07-aggregations.md) - Agrégations et statistiques
- [08-websocket.md](08-websocket.md) - Temps réel avec WebSocket
- [09-files-assets.md](09-files-assets.md) - Gestion des fichiers et assets
- [10-users.md](10-users.md) - Gestion des utilisateurs
- [11-error-handling.md](11-error-handling.md) - Gestion des erreurs
