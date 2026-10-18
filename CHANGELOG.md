# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-18

Mise en conformité avec l'API Directus 12.5. Détail route par route : `docs/13-api-coverage.md`.

### Fixed

- **Collections système** : `ItemsService` et `ItemActiveService` appelaient `/items/directus_*`, que Directus refuse (403). Les collections `directus_*` sont maintenant routées vers leur endpoint (`/comments`, `/files`, `/flows`...) via `directusCollectionPath()`. Cela corrige comments, dashboards, panels, flows, operations, folders, notifications, presets, shares, translations, versions, revisions, files (lecture/maj), permissions et `itemsOf<DirectusXxx>()`.
- **WebSocket** : les messages sortants sont désormais à plat (`{"type":"auth","access_token":…}`) comme l'exige Directus ; les événements de souscription (`data` = liste) ne font plus échouer le parsing.
- **Relations** : routes `/relations/{collection}/{field}` (il n'y a pas d'identifiant numérique) ; `DirectusRelation` lit `related_collection` et l'objet `meta`.
- **Versions** : `compare`, `save` et `promote` utilisent `/versions/{id}/…`.
- **Extensions** : mise à jour via `PATCH /extensions/{uuid}`.
- **Utilitaires** : `export` en `POST` avec `query`/`format`, `import` en multipart, `cache.clear(system:)`, `sort.reorder` attend des clés primaires.
- **Fichiers** : métadonnées envoyées avant le binaire (elles étaient ignorées) ; `importFile` n'écrase plus `title` avec `folder` ; suppression de `dart:io` (compatibilité Flutter Web).
- **Auth** : providers via `GET /auth`, URL SSO `/auth/login/{provider}`, refresh en mode cookie sans token local, réponse du mode session sans token.
- **Serveur / métriques / permissions** : `server.health/info/specs`, `metrics.getMetrics` et `permissions.getMyPermissions/getItemPermissions` retournent les données au lieu de l'objet `Response` ; `/metrics` est lu en texte Prometheus.
- **Utilisateurs** : `verifyEmail` utilise `?token=`.
- **Erreurs** : `statusCode` conservé pour les exceptions issues d'un code Directus ; ajout des codes 12.x (`COLLECTION_INACTIVE`, `LICENSE_INVALID`, `RESOURCE_RESTRICTED`, `VERSION_HASH_MISMATCH`…).
- L'intercepteur n'écrase plus un en-tête `Authorization` explicite.

### Added

- Classes de base `DirectusReadOnlySystemService<T>` / `DirectusSystemService<T>` : API objet (`readMany`, `readOne`, `createOne`, `updateOne`, `deleteOne`…) sur les services système.
- Modèles `DirectusFile`, `DirectusShare`, `DirectusTranslation`, `DirectusVersion`, `DirectusAccess`, `DirectusSettings`, `DirectusRelationMeta` ; champ `DirectusFolder.type`.
- Services `access`, `license`, `deployments`.
- `auth.loginWithProvider()` (LDAP), `users.disableTwoFactorForUser()`, `roles.getMyRoles()`, `policies.getMyGlobals()`, `settings.read/update/setOwner`, `shares.authenticate/invite/info`, `collections.updateCollections`, `fields.updateFields`, `files.upload/replace/importFromUrl`, `assets.download/downloadFolderZip/downloadFilesZip`, `server.graphqlSdl/setup`, `utilities.importBatch/revert/generateTranslations/resolveRedirect`, registre d'extensions, `websocket.items()`.
- `QueryParameters` : `meta`, `alias`, `version`, `versionRaw`, `backlink` ; `toJsonBody()`.
- Factories des modèles système enregistrées par défaut (`itemsOf<DirectusUser>()` fonctionne sans configuration).

### Deprecated

- `utilities.hash` (endpoints supprimés en 12.1), `cache.clearCollection`, `auth.loginWithOAuth` (lève `UnsupportedError`), anciennes méthodes de `RelationsService` basées sur un id, `versions.promoteVersion/saveItemAsVersion/compareVersions`, `extensions.updateExtensionInBundle`.

### Changed

- Signatures corrigées (l'ancien comportement ne fonctionnait pas) : `utilities.export` (`DirectusExportFormat`, `QueryParameters`), `utilities.import` (octets), types de retour de `ServerService`, `MetricsService`, `getMyPermissions`, `getItemPermissions`.
- `DirectusWebSocketMessage.data` est `dynamic` (liste ou objet selon le message) ; ajout de `items`, `ids`, `status`, `error`, `raw`.

## [Unreleased]

### Added

- **onAuthError callback** : Nouveau callback dans `DirectusConfig` pour centraliser la gestion des erreurs d'authentification
  - ✅ Notifie l'application lors de l'échec de l'auto-refresh (refresh token expiré)
  - ✅ Notifie de toutes les erreurs `DirectusAuthException` (login échoué, compte suspendu, etc.)
  - ✅ Permet de rediriger automatiquement vers l'écran de login
  - ✅ Compatible avec les systèmes d'état (Bloc, Riverpod, Provider, etc.)
  - ✅ Complète le callback `onTokenRefreshed` pour une gestion complète
  - 📚 Documentation : `docs/auth-error-callback.md`
  - 📝 Exemple : `example/example_auth_error_callback.dart`
  - 🧪 Tests : 8 tests unitaires

- **EnumProperty** : Nouveau property wrapper pour la gestion des enums type-safe
  - ✅ Conversion automatique String ↔ Enum
  - ✅ Insensible à la casse
  - ✅ Gestion des valeurs invalides avec fallback vers la valeur par défaut
  - ✅ Méthodes utilitaires : `is_()`, `isOneOf()`, `allValues`, `reset()`
  - ✅ Propriété `asString` pour obtenir la représentation String
  - ✅ Intégration complète avec le dirty tracking
  - 📚 Documentation : `docs/enum-property.md`
  - 📝 Exemple : `example/example_enum_property.dart`
  - 🧪 Tests : 21 tests unitaires

### Fixed

- **CRITICAL: 404 sur /auth/refresh** : Les headers personnalisés (`DirectusConfig.headers`) sont maintenant inclus dans le Dio temporaire utilisé pour le refresh du token. Ceci résout les erreurs 404 lorsque Directus est derrière un reverse proxy ou une API Gateway nécessitant des headers spécifiques.
  - 📚 Documentation : `docs/FIX_404_REFRESH_TOKEN.md`
  - 🎯 Impact : Reverse proxies, API Gateways, headers de routing

- **BREAKING FIX: Notation pointée dans les filtres** : `Filter.field('departement.region')` crée maintenant correctement une structure JSON imbriquée `{"departement": {"region": {...}}}` au lieu de `{"departement.region": {...}}`. Ceci corrige les erreurs de permissions avec Directus et rend la syntaxe conforme à l'API Directus.
  - ✅ Équivalence complète avec `Filter.relation().where()`
  - ✅ Support multi-niveaux : `Filter.field('a.b.c.d')`
  - ✅ Compatible avec tous les opérateurs
  - 📚 Documentation : `docs/NESTED_FILTER_FIX.md`
  - 🧪 Tests : 18 tests de filtres imbriqués

### Added

- Script de diagnostic des permissions : `example/debug_permissions.dart`
- Documentation complète du troubleshooting : `docs/troubleshooting-permissions.md`
- Guide des filtres sur champs imbriqués : `docs/nested-field-filters.md` (mis à jour)

## [0.2.0] - 2025-10-30

### Added

- **Documentation complète** : README détaillé avec tous les cas d'usage
- **Exemples pratiques** :
  - `example_basic.dart` : Opérations CRUD de base
  - `example_filters.dart` : Utilisation avancée des filtres
  - `example_relations.dart` : Deep queries et relations imbriquées
  - `example_custom_model.dart` : Création de modèles personnalisés
- **Property Wrappers** : API simplifiée pour l'accès aux propriétés des modèles
  - `StringProperty`, `IntProperty`, `DoubleProperty`, `BoolProperty`
  - `DateTimeProperty`, `ListProperty`, `ObjectProperty`
  - `ModelProperty`, `ModelListProperty`
- **Système de filtres type-safe** amélioré :
  - Support des filtres sur relations (`Filter.relation()`)
  - Support des filtres relationnels (`Filter.some()`, `Filter.none()`)
  - Opérateurs de chaîne insensibles à la casse
  - Opérateurs géographiques (intersects, bbox)
  - Validation des filtres
- **Deep Query System** :
  - Builder pattern pour les requêtes relationnelles
  - Support des relations imbriquées à plusieurs niveaux
  - Filtres, tri et limite sur les relations
- **Aggregate System** :
  - Support complet des agrégations (count, sum, avg, min, max)
  - GroupBy avec plusieurs champs
  - Agrégations avec filtres
- **WebSocket Client** :
  - Connexion temps réel aux collections Directus
  - Support des événements CRUD (create, update, delete)
  - Souscriptions avec filtres
  - Support des collections système
- **Services complets** :
  - 30+ services couvrant toute l'API Directus
  - Collections, Fields, Relations, Schema
  - Activity, Revisions, Comments
  - Dashboards, Panels, Flows, Operations
  - Server, Settings, Utilities
- **Gestion d'erreurs robuste** :
  - Exceptions typées pour tous les cas d'erreur
  - Codes d'erreur officiels Directus
  - Extensions et métadonnées d'erreur
- **Modèles système** :
  - `DirectusUser`, `DirectusRole`, `DirectusPolicy`
  - `DirectusFile`, `DirectusFolder`
  - `DirectusActivity`, `DirectusRevision`, `DirectusComment`
  - `DirectusNotification`, `DirectusPermission`, `DirectusPreset`
  - `DirectusRelation`, `DirectusField`, `DirectusCollection`
- **Active Record Pattern** :
  - Stockage JSON interne dans les modèles
  - Tracking des modifications (dirty fields)
  - Factory registration pour les modèles typés
- **Asset Transformations** :
  - Builder pour les transformations d'images
  - Support des formats (WebP, JPEG, PNG, etc.)
  - Redimensionnement, recadrage, qualité
  - Presets d'assets

### Changed

- **Architecture améliorée** : Séparation claire entre core, services, models, utils
- **Documentation API** : Tous les commentaires conformes aux normes Dart/Flutter
- **Tests** : Augmentation de la couverture de tests

### Fixed

- Correction des types de retour pour certaines méthodes
- Amélioration de la gestion des erreurs réseau
- Correction des problèmes de sérialisation JSON

## [0.1.0] - Initial Release

### Added

- Client HTTP de base pour Directus
- Authentification (login, logout, refresh)
- Service Items pour CRUD basique
- Support des filtres simples
- Configuration flexible
- Gestion basique des erreurs

---

[0.2.0]: https://github.com/fracosfr/fcs_directus/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/fracosfr/fcs_directus/releases/tag/v0.1.0
