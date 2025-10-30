# Getting Started

Guide d'installation et de premiers pas avec fcs_directus.

## 📋 Prérequis

- **Dart SDK** : ≥3.9.2
- **Flutter** : ≥1.17.0 (si utilisé dans une app Flutter)
- **Serveur Directus** : Instance Directus accessible (v10+)

## 📦 Installation

### Ajouter la dépendance

Ajoutez `fcs_directus` à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  fcs_directus: ^0.2.0
```

Puis exécutez :

```bash
flutter pub get
# ou
dart pub get
```

### Import

```dart
import 'package:fcs_directus/fcs_directus.dart';
```

## 🚀 Configuration de base

### Créer une instance DirectusClient

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.cookie, // cookie (défaut), json, ou staticToken
  ),
);
```

### Options de configuration

```dart
final config = DirectusConfig(
  baseUrl: 'https://api.example.com',
  
  // Mode d'authentification
  authMode: AuthMode.cookie, // cookie, json, staticToken
  
  // Timeout des requêtes (optionnel)
  timeout: Duration(seconds: 30),
  
  // Token statique (si authMode = staticToken)
  staticToken: 'your-static-token',
  
  // Headers personnalisés (optionnel)
  headers: {
    'X-Custom-Header': 'value',
  },
);

final directus = DirectusClient(config);
```

## 🔐 Authentification

### Login avec email/password

```dart
try {
  final response = await directus.auth.login(
    email: 'admin@example.com',
    password: 'your-password',
  );
  
  print('Access token: ${response.accessToken}');
  print('Expires: ${response.expires}');
} on DirectusAuthException catch (e) {
  print('Erreur d\'authentification: ${e.message}');
}
```

### Token statique

Pour utiliser un token statique (sans login) :

```dart
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
    authMode: AuthMode.staticToken,
    staticToken: 'your-static-admin-token',
  ),
);

// Pas besoin de login, toutes les requêtes utilisent le token statique
```

### Vérifier l'authentification

```dart
final isAuthenticated = await directus.auth.isAuthenticated();
print('Authentifié: $isAuthenticated');
```

## 📝 Premier exemple complet

Voici un exemple complet d'utilisation basique :

```dart
import 'package:fcs_directus/fcs_directus.dart';

Future<void> main() async {
  // 1. Configuration
  final directus = DirectusClient(
    DirectusConfig(
      baseUrl: 'https://your-directus-instance.com',
    ),
  );

  try {
    // 2. Authentification
    await directus.auth.login(
      email: 'admin@example.com',
      password: 'password',
    );
    print('✅ Authentifié avec succès');

    // 3. Lire des données
    final articles = await directus.items('articles').readMany();
    print('📚 ${articles.data?.length ?? 0} articles trouvés');

    // 4. Créer un item
    final newArticle = await directus.items('articles').createOne(
      item: {
        'title': 'Mon premier article',
        'content': 'Contenu de l\'article',
        'status': 'published',
      },
    );
    print('✅ Article créé: ${newArticle.data?['title']}');

    // 5. Mettre à jour
    await directus.items('articles').updateOne(
      id: newArticle.data?['id'],
      item: {
        'title': 'Titre modifié',
      },
    );
    print('✅ Article mis à jour');

    // 6. Supprimer
    await directus.items('articles').deleteOne(
      id: newArticle.data?['id'],
    );
    print('✅ Article supprimé');

    // 7. Déconnexion
    await directus.auth.logout();
    print('✅ Déconnecté');

  } on DirectusException catch (e) {
    print('❌ Erreur: ${e.message}');
    print('Code: ${e.code}');
  }
}
```

## 🔍 Requêtes avec filtres

Ajoutez des filtres, pagination et tri à vos requêtes :

```dart
final result = await directus.items('articles').readMany(
  query: QueryParameters(
    // Filtrer
    filter: {
      'status': {'_eq': 'published'},
      'date_created': {'_gte': '2024-01-01'},
    },
    
    // Trier
    sort: ['-date_created'], // - pour desc, sans - pour asc
    
    // Paginer
    limit: 10,
    offset: 0,
    
    // Sélectionner des champs
    fields: ['id', 'title', 'content', 'author.name'],
  ),
);

print('Articles: ${result.data?.length}');
print('Total: ${result.meta?.totalCount}');
```

## 🎯 Services disponibles

La librairie fournit 30+ services pour interagir avec toutes les fonctionnalités Directus :

```dart
// Items (collections personnalisées)
directus.items('collection_name')

// Authentification
directus.auth

// Utilisateurs
directus.users

// Fichiers
directus.files

// Dossiers
directus.folders

// Rôles et permissions
directus.roles
directus.permissions
directus.policies

// Activité et révisions
directus.activity
directus.revisions

// Et bien plus...
```

Consultez [08-services.md](08-services.md) pour la liste complète.

## 📖 Prochaines étapes

Maintenant que vous avez configuré fcs_directus, explorez les guides suivants :

1. [**Core Concepts**](02-core-concepts.md) - Comprendre l'architecture de la librairie
2. [**Models**](04-models.md) - Créer vos propres modèles Dart
3. [**Queries**](05-queries.md) - Maîtriser le système de requêtes type-safe
4. [**Relationships**](06-relationships.md) - Gérer les relations entre collections

## 💡 Conseils

### Organisation du code

Il est recommandé de créer une classe singleton pour votre client Directus :

```dart
// lib/services/directus_service.dart
class DirectusService {
  static final DirectusService _instance = DirectusService._internal();
  late final DirectusClient client;

  factory DirectusService() => _instance;

  DirectusService._internal() {
    client = DirectusClient(
      DirectusConfig(
        baseUrl: 'https://your-directus-instance.com',
      ),
    );
  }
}

// Utilisation dans votre app
final directus = DirectusService().client;
```

### Variables d'environnement

Ne hardcodez jamais vos credentials. Utilisez des variables d'environnement :

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();

final directus = DirectusClient(
  DirectusConfig(
    baseUrl: dotenv.env['DIRECTUS_URL']!,
  ),
);

await directus.auth.login(
  email: dotenv.env['DIRECTUS_EMAIL']!,
  password: dotenv.env['DIRECTUS_PASSWORD']!,
);
```

### Gestion des erreurs

Toujours wrapper vos appels dans des try-catch :

```dart
try {
  final result = await directus.items('articles').readMany();
  // Traiter le résultat
} on DirectusAuthException catch (e) {
  // Erreur d'authentification
  print('Auth error: ${e.message}');
} on DirectusValidationException catch (e) {
  // Erreur de validation
  print('Validation errors: ${e.errors}');
} on DirectusException catch (e) {
  // Autres erreurs Directus
  print('Error: ${e.message}');
} catch (e) {
  // Erreurs inattendues
  print('Unexpected error: $e');
}
```

## ⚠️ Points d'attention

### CORS

Si vous utilisez fcs_directus dans une application web, assurez-vous que votre instance Directus autorise les requêtes CORS depuis votre domaine.

### Sécurité

- Ne stockez jamais les tokens en clair dans votre code
- Utilisez HTTPS pour toutes les communications
- Respectez les permissions Directus pour chaque utilisateur
- Utilisez des tokens statiques avec précaution (limitez les permissions)

### Performance

- Utilisez la pagination pour les grandes collections
- Limitez les champs retournés avec le paramètre `fields`
- Utilisez le cache quand c'est approprié
- Évitez les deep queries trop profondes

## 🔗 Ressources

- [Documentation complète](README.md)
- [API Reference](api-reference/)
- [Exemples](examples/)
- [API Directus](https://docs.directus.io/reference/api/)
