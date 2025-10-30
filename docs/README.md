# Documentation fcs_directus

Documentation complète de la librairie Dart/Flutter pour interagir avec l'API Directus.

## 📚 Table des matières

### Guide d'utilisation

1. [**Getting Started**](01-getting-started.md) - Installation et premiers pas
2. [**Core Concepts**](02-core-concepts.md) - Concepts fondamentaux de la librairie
3. [**Authentication**](03-authentication.md) - Gestion de l'authentification
4. [**Models**](04-models.md) - Création de modèles personnalisés
5. [**Queries**](05-queries.md) - Requêtes et filtres
6. [**Relationships**](06-relationships.md) - Relations et deep queries
7. [**Aggregations**](07-aggregations.md) - Agrégations et fonctions
8. [**Services**](08-services.md) - Services disponibles
9. [**WebSockets**](09-websockets.md) - Communication temps réel
10. [**File Management**](10-file-management.md) - Gestion des fichiers et assets
11. [**Error Handling**](11-error-handling.md) - Gestion des erreurs
12. [**Advanced**](12-advanced.md) - Fonctionnalités avancées

### Référence API

- [**Services**](api-reference/services/) - Documentation détaillée de tous les services
  - [AuthService](api-reference/services/auth-service.md)
  - [ItemsService](api-reference/services/items-service.md)
  - [UsersService](api-reference/services/users-service.md)
  - [FilesService](api-reference/services/files-service.md)
  - [Et 30+ autres services...](api-reference/services/)
  
- [**Models**](api-reference/models/) - Documentation des modèles principaux
  - [DirectusModel](api-reference/models/directus-model.md)
  - [DirectusFilter](api-reference/models/directus-filter.md)
  - [DirectusDeep](api-reference/models/directus-deep.md)
  - [DirectusAggregate](api-reference/models/directus-aggregate.md)
  - [Property Wrappers](api-reference/models/property-wrappers.md)

- [**Exceptions**](api-reference/exceptions.md) - Gestion des erreurs et exceptions

### Exemples

- [**Basic CRUD**](examples/basic-crud.md) - Opérations CRUD de base
- [**Advanced Filters**](examples/advanced-filters.md) - Filtres avancés
- [**Complex Relationships**](examples/complex-relationships.md) - Relations complexes
- [**Real World Scenarios**](examples/real-world-scenarios.md) - Scénarios réels

## 🚀 Quick Start

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Configuration
final directus = DirectusClient(
  DirectusConfig(
    baseUrl: 'https://your-directus-instance.com',
  ),
);

// Authentification
await directus.auth.login(
  email: 'admin@example.com',
  password: 'password',
);

// Utilisation des services
final items = await directus.items('articles').readMany();

// Gestion d'erreur avec helpers
try {
  await directus.auth.login(email: email, password: password);
} on DirectusAuthException catch (e) {
  if (e.isOtpRequired) {
    print('Code 2FA requis');
  }
  if (e.isInvalidCredentials) {
    print('Identifiants incorrects');
  }
}
```

Pour plus de détails, consultez le [guide Getting Started](01-getting-started.md).

## 📖 À propos

**Version actuelle** : 0.2.0

Cette librairie fournit une interface Dart/Flutter complète pour interagir avec l'API Directus, incluant :

- ✅ 30+ services pour toutes les fonctionnalités Directus
- ✅ Système de filtres type-safe
- ✅ Deep queries pour les relations
- ✅ Agrégations et fonctions
- ✅ Support WebSocket pour le temps réel
- ✅ Pattern Active Record pour les modèles
- ✅ Gestion complète des fichiers et transformations d'images
- ✅ Gestion robuste des erreurs
- ✅ Support de l'authentification (cookie, JSON, static token)

## 🎯 Navigation rapide par cas d'usage

### Je veux...

- **Installer la librairie** → [01-getting-started.md](01-getting-started.md)
- **M'authentifier** → [03-authentication.md](03-authentication.md)
- **Créer mes modèles** → [04-models.md](04-models.md)
- **Faire des requêtes simples** → [05-queries.md](05-queries.md)
- **Filtrer mes données** → [05-queries.md#filtres](05-queries.md)
- **Gérer les relations** → [06-relationships.md](06-relationships.md)
- **Faire des agrégations** → [07-aggregations.md](07-aggregations.md)
- **Uploader des fichiers** → [10-file-management.md](10-file-management.md)
- **Recevoir des événements en temps réel** → [09-websockets.md](09-websockets.md)
- **Gérer les erreurs** → [11-error-handling.md](11-error-handling.md)

### Par service Directus

Consultez le [guide des services](08-services.md) pour une vue d'ensemble, ou accédez directement à la documentation d'un service spécifique dans [api-reference/services/](api-reference/services/).

## 📝 Conventions

Cette documentation utilise les conventions suivantes :

- `Code inline` : noms de classes, méthodes, variables
- **Gras** : termes importants ou titres
- 💡 : Conseil ou bonne pratique
- ⚠️ : Avertissement ou point d'attention
- ✅ : Fonctionnalité disponible
- 🔧 : Configuration requise

## 🔗 Ressources externes

- [API Directus officielle](https://docs.directus.io/reference/api/)
- [Spécifications OpenAPI](../openapi/index.yaml)
- [Dépôt GitHub](https://github.com/fracosfr/fcs_directus)
- [pub.dev](https://pub.dev/packages/fcs_directus)

## 🤝 Contribution

Cette documentation doit rester à jour avec l'état actuel de la librairie. Si vous constatez des incohérences ou des informations obsolètes, veuillez les corriger.

Consultez [CONTRIBUTING.md](../CONTRIBUTING.md) pour plus d'informations sur la contribution au projet.
