# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

# Changelog

## [0.2.0] - 2024-01-15

### ✨ Nouvelles fonctionnalités majeures

#### Builder Pattern pour les modèles
- **DirectusModelBuilder** : Parse le JSON avec des getters type-safe
  - Champs standards : `id`, `dateCreated`, `dateUpdated`, `userCreated`, `userUpdated`
  - Getters typés : `getString`, `getInt`, `getDouble`, `getBool`, `getDateTime`, `getList`, `getObject`
  - Variants null-safe : `getStringOrNull`, `getIntOrNull`, etc.
  - Valeurs par défaut intégrées
  - Conversions automatiques (string→int, "true"→bool, etc.)

- **DirectusMapBuilder** : Construction fluide de Maps
  - `add(key, value)` - Toujours ajouter
  - `addIfNotNull(key, value)` - Ajouter seulement si non-null
  - `addIf(condition, key, value)` - Ajouter conditionnellement
  - `addAll(map)` - Ajouter plusieurs champs
  - `addRelation(key, id)` - Ajouter une relation (si non-null)
  - `build()` - Retourne la Map finale

- **DirectusModelRegistry** : Gestion des factories
  - `register<T>(factory)` - Enregistrer un modèle
  - `create<T>(json)` - Créer une instance depuis JSON
  - `createList<T>(jsonList)` - Créer une liste depuis JSON array
  - `isRegistered<T>()` - Vérifier l'enregistrement
  - `unregister<T>()` - Désenregistrer un modèle
  - `clear()` - Effacer tous les enregistrements

#### Annotations pour génération de code future
- `@directusModel` - Marque une classe pour la génération
- `@DirectusField('json_name')` - Map un nom de champ personnalisé
- `@DirectusRelation()` - Indique un champ de relation
- `@DirectusIgnore()` - Exclut un champ de la sérialisation

#### DirectusSerializable Mixin
- Mixin générique `DirectusSerializable<T>` pour typages avancés
- Prépare la future génération automatique de code

### 📖 Documentation

- Nouveau guide complet : `docs/MODELS_GUIDE.md`
  - Introduction aux concepts
  - Guide détaillé du DirectusModelBuilder
  - Guide détaillé du DirectusMapBuilder
  - Exemples avancés (relations, champs calculés, validation)
  - Registry Pattern
  - Annotations
  - Bonnes pratiques

- README enrichi avec :
  - Section Builders API Reference
  - Comparaison approches (Builders vs Manuelle)
  - Exemples avec DirectusMapBuilder
  - Section Annotations

- Nouveaux exemples :
  - `example/advanced_builders_example.dart` - Exemple complexe avec Product/User et relations

### 🧪 Tests

- 28 nouveaux tests pour les Builders
- Total : 57 tests (100% passing)
- Couverture :
  - DirectusModelBuilder : getters, conversions, null safety, defaults
  - DirectusMapBuilder : add, addIfNotNull, addIf, addAll, addRelation
  - DirectusModelRegistry : register, create, createList, isRegistered, unregister, clear
  - Intégration : fromJson → toMap → toJson round-trip

### 🔧 Améliorations

- Réduction de ~50% du code dans les modèles
- Élimination complète du code JSON dans les classes métier
- Type safety renforcée avec conversions automatiques
- API fluide pour la construction de Maps
- Séparation totale logique métier / sérialisation

### 📦 Exports

- `lib/fcs_directus.dart` mis à jour avec :
  - `DirectusModelBuilder`
  - `DirectusMapBuilder`
  - `DirectusSerializable`
  - `DirectusModelRegistry`
  - Toutes les annotations

---

## [0.1.0] - 2024-01-14

### Ajouté
- ✨ Architecture de base de la librairie
- 🔐 Service d'authentification (login, logout, refresh token, static tokens)
- 📦 Service Items pour opérations CRUD sur les collections
- 📚 Service Collections pour gérer les collections Directus
- 👥 Service Users pour la gestion des utilisateurs
- 📁 Service Files pour l'upload et la gestion des fichiers
- 🌐 Support WebSocket pour les mises à jour en temps réel
- 🔧 Configuration flexible avec DirectusConfig
- 🛡️ Système d'exceptions typées (Auth, Validation, NotFound, Network, Server, Permission)
- 📊 Support des paramètres de requête (filtres, tri, pagination, recherche)
- 🎨 **DirectusModel** - Classe de base abstraite pour les modèles personnalisés
  - Gestion automatique des champs standards (id, date_created, date_updated)
  - Helpers pour parser dates et IDs
  - Implémentation d'equals et hashCode
  - Réduction du code boilerplate
- 📝 Documentation complète avec Dartdoc
- ✅ Tests unitaires (29 tests dont 11 pour DirectusModel)
- 📖 Exemples d'utilisation (basic_usage, custom_model, directus_model_example, websocket_example)
- 🎯 Support des modèles Dart personnalisés

### Dépendances
- dio: ^5.7.0 - Client HTTP
- web_socket_channel: ^3.0.1 - Support WebSocket
- json_annotation: ^4.9.0 - Sérialisation JSON
- logging: ^1.2.0 - Gestion des logs

[0.0.1]: https://github.com/fracosfr/fcs_directus/releases/tag/v0.0.1
