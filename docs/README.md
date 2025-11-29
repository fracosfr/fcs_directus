# Documentation fcs_directus

Bienvenue dans la documentation complète de la librairie fcs_directus.

## Table des matières

### Guides

1. **[Démarrage rapide](01-getting-started.md)**
   - Installation
   - Configuration
   - Première requête
   - Structure recommandée

2. **[Authentification](02-authentication.md)**
   - Login email/password
   - Token statique
   - OAuth/SSO
   - Gestion de session
   - Two-Factor Authentication

3. **[Opérations CRUD](03-crud-operations.md)**
   - Créer des items
   - Lire des items
   - Mettre à jour
   - Supprimer
   - Pagination
   - Tri et recherche

4. **[Modèles personnalisés](04-custom-models.md)**
   - Créer un modèle
   - Property Wrappers
   - Enums type-safe
   - Relations
   - Dirty tracking

5. **[Filtres](05-filters.md)**
   - Filtres de champs
   - Opérateurs disponibles
   - Combinaisons AND/OR
   - Filtres relationnels
   - Filtres dynamiques

6. **[Deep Queries](06-deep-queries.md)**
   - Charger les relations
   - Configuration des DeepQuery
   - Relations imbriquées
   - Relations M2M

7. **[Agrégations](07-aggregations.md)**
   - Count, Sum, Avg, Min, Max
   - GroupBy
   - Statistiques avancées

8. **[WebSocket](08-websocket.md)**
   - Configuration
   - Abonnements
   - Événements temps réel
   - Collections système

9. **[Fichiers et Assets](09-files-assets.md)**
   - Upload de fichiers
   - Gestion des dossiers
   - Transformation d'images
   - Helpers prédéfinis

10. **[Gestion des utilisateurs](10-users.md)**
    - CRUD utilisateurs
    - Invitations
    - 2FA
    - Rôles et permissions

11. **[Gestion des erreurs](11-error-handling.md)**
    - Hiérarchie des exceptions
    - Codes d'erreur
    - Patterns de gestion
    - Bonnes pratiques

## Services disponibles

| Service | Description | Documentation |
|---------|-------------|---------------|
| `auth` | Authentification | [Guide Auth](02-authentication.md) |
| `items(collection)` | CRUD générique | [Guide CRUD](03-crud-operations.md) |
| `itemsOf<T>()` | CRUD typé | [Guide Modèles](04-custom-models.md) |
| `users` | Gestion utilisateurs | [Guide Users](10-users.md) |
| `roles` | Gestion des rôles | [Guide Users](10-users.md) |
| `policies` | Politiques d'accès | [Guide Users](10-users.md) |
| `permissions` | Permissions | [Guide Users](10-users.md) |
| `files` | Upload fichiers | [Guide Files](09-files-assets.md) |
| `assets` | Transformation images | [Guide Files](09-files-assets.md) |
| `folders` | Organisation fichiers | [Guide Files](09-files-assets.md) |
| `websocket` | Temps réel | [Guide WebSocket](08-websocket.md) |
| `collections` | Schéma collections | API Reference |
| `fields` | Gestion des champs | API Reference |
| `relations` | Gestion des relations | API Reference |
| `activity` | Logs d'activité | API Reference |
| `revisions` | Historique | API Reference |
| `comments` | Commentaires | API Reference |
| `notifications` | Notifications | API Reference |
| `presets` | Préférences | API Reference |
| `dashboards` | Tableaux de bord | API Reference |
| `panels` | Panneaux | API Reference |
| `flows` | Automatisation | API Reference |
| `operations` | Opérations flows | API Reference |
| `shares` | Partage | API Reference |
| `versions` | Versioning | API Reference |
| `translations` | Traductions | API Reference |
| `extensions` | Extensions | API Reference |
| `schema` | Snapshot schéma | API Reference |
| `settings` | Paramètres | API Reference |
| `server` | Info serveur | API Reference |
| `utilities` | Utilitaires | API Reference |
| `metrics` | Métriques | API Reference |

## Liens utiles

- **[README](../README.md)** - Vue d'ensemble et exemples rapides
- **[API Reference](../doc/api/index.html)** - Documentation générée (dart doc)
- **[CHANGELOG](../CHANGELOG.md)** - Historique des versions
- **[CONTRIBUTING](../CONTRIBUTING.md)** - Guide de contribution

## Ressources externes

- [Documentation Directus](https://directus.io/docs)
- [API Reference Directus](https://directus.io/docs/api)
- [Communauté Directus](https://directus.io/community)

## Support

Pour toute question ou problème :
- Ouvrir une [issue sur GitHub](https://github.com/fracosfr/fcs_directus/issues)
- Consulter les [discussions](https://github.com/fracosfr/fcs_directus/discussions)
