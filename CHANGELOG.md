# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
