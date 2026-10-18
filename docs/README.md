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
   - OAuth/SSO, LDAP
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

12. **[Services système orientés objet](12-system-services.md)**
    - Routage des collections `directus_*`
    - Classes de base typées
    - Modèles système (fichiers, commentaires, versions, accès...)

13. **[Couverture de l'API](13-api-coverage.md)**
    - Correspondance route Directus ↔ méthode
    - Routes non couvertes
    - Changements Directus 11.1 → 12.5

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
| `access` | Attribution des policies | [Guide Users](10-users.md) |
| `collections` | Schéma collections | [Couverture API](13-api-coverage.md) |
| `fields` | Gestion des champs | [Couverture API](13-api-coverage.md) |
| `relations` | Relations (typées) | [Services système](12-system-services.md) |
| `activity` | Logs d'activité (typés) | [Services système](12-system-services.md) |
| `revisions` | Historique (typé) | [Services système](12-system-services.md) |
| `comments` | Commentaires (typés) | [Services système](12-system-services.md) |
| `notifications` | Notifications (typées) | [Services système](12-system-services.md) |
| `presets` | Préférences (typées) | [Services système](12-system-services.md) |
| `dashboards` | Tableaux de bord (typés) | [Services système](12-system-services.md) |
| `panels` | Panneaux (typés) | [Services système](12-system-services.md) |
| `flows` | Automatisation (typée) | [Services système](12-system-services.md) |
| `operations` | Opérations flows (typées) | [Services système](12-system-services.md) |
| `shares` | Partage (typé) | [Services système](12-system-services.md) |
| `versions` | Versioning (typé) | [Services système](12-system-services.md) |
| `translations` | Traductions (typées) | [Services système](12-system-services.md) |
| `extensions` | Extensions et marketplace | [Couverture API](13-api-coverage.md) |
| `schema` | Snapshot / diff / apply | [Couverture API](13-api-coverage.md) |
| `settings` | Paramètres (typés) | [Services système](12-system-services.md) |
| `server` | Ping, santé, infos, specs, setup | [Couverture API](13-api-coverage.md) |
| `utilities` | Random, cache, tri, import/export, revert | [Couverture API](13-api-coverage.md) |
| `metrics` | Métriques Prometheus | [Couverture API](13-api-coverage.md) |
| `license` | Licence Directus | [Couverture API](13-api-coverage.md) |
| `deployments` | Déploiements (Vercel, Netlify...) | [Couverture API](13-api-coverage.md) |

## Liens utiles

- **[README](../README.md)** - Vue d'ensemble et exemples rapides
- **[API Reference](../doc/api/index.html)** - Documentation générée (dart doc)
- **[CHANGELOG](../CHANGELOG.md)** - Historique des versions
- **[CONTRIBUTING](../CONTRIBUTING.md)** - Guide de contribution

## Ressources externes

- [Documentation Directus](https://directus.com/docs)
- [API Reference Directus](https://directus.com/docs/api)
- [Breaking changes Directus](https://directus.com/docs/releases/breaking-changes/version-12)
- [Communauté Directus](https://directus.io/community)

## Support

Pour toute question ou problème :
- Ouvrir une [issue sur GitHub](https://github.com/fracosfr/fcs_directus/issues)
- Consulter les [discussions](https://github.com/fracosfr/fcs_directus/discussions)
