# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [0.4.0] - 2025-10-30

### ✨ Nouvelles fonctionnalités majeures

#### API Activity (Historique des actions) ⭐ NOUVEAU
- **Service `ActivityService`** pour consulter l'historique complet des activités Directus
  - Accessible via `client.activity`
  - Support de tous les types d'actions : `create`, `update`, `delete`, `login`
  - Lecture seule (les activités sont créées automatiquement par Directus)

- **Méthodes principales**
  - `getActivities()` : Liste des activités avec filtres personnalisés
  - `getActivity(id)` : Récupérer une activité par son ID
  - `getRecentActivities()` : Activités récentes (24h par défaut, configurable)
  - `getUserActivities(userId)` : Toutes les activités d'un utilisateur
  - `getCollectionActivities(collection)` : Activités d'une collection spécifique
  - `getItemActivities(itemId, collection)` : Historique complet d'un item
  - `getActivitiesByAction(action)` : Filtrer par type d'action

- **Modèle `DirectusActivity`**
  - Propriétés complètes : `action`, `user`, `timestamp`, `collection`, `item`, `ip`, `userAgent`, `comment`, `revisions`
  - Relations : `user` (DirectusUser), `revisions` (List<DirectusRevision>)
  - Helpers booléens : `isCreate`, `isUpdate`, `isDelete`, `isLogin`, `hasComment`, `hasRevisions`
  - Accesseurs pratiques : `actor`, `actorName`, `actorEmail`, `actionDescription`, `formattedTimestamp`, `summary`

- **Modèle `DirectusRevision`**
  - Représente les changements spécifiques dans une activité
  - Propriétés : `activity`, `collection`, `item`, `data`, `delta`, `parent`, `version`
  - Helpers : `hasData`, `hasDelta`, `hasParent`, `changesCount`, `changedFields`

- **Méthodes helper avec filtres préconfigurés**
  - Filtrage automatique par utilisateur, collection, item ou action
  - Paramètre `additionalQuery` pour combiner avec des filtres personnalisés
  - Tri par défaut sur `-timestamp` (plus récent en premier)
  - Support complet de Deep pour charger les relations (utilisateur, révisions)

- **Exemples d'utilisation**
  - Fichier d'exemple complet : `example/activity_example.dart` (12 scénarios)
  - Documentation complète dans README.md avec exemples de code
  - Support des filtres avancés (AND/OR, plages de dates, etc.)
  - Utilisation avec Deep pour enrichir les données

- **Cas d'usage**
  - Audit trail complet (qui a fait quoi, quand)
  - Surveillance des connexions (IP, user agent, timestamp)
  - Historique des modifications d'un item
  - Statistiques d'activité par type/utilisateur/collection
  - Détection d'activité suspecte ou anormale
  - Rapports d'activité personnalisés

### 📦 Exports

- Ajout de `ActivityService` dans les exports
- Ajout de `DirectusActivity` dans les exports de modèles
- Ajout de `DirectusRevision` dans les exports de modèles

### 📖 Documentation

- Section complète "Gestion des activités" dans README.md
- Exemple détaillé avec 12 scénarios dans `example/activity_example.dart`
- Documentation inline complète dans tous les fichiers

## [0.3.0] - 2024-01-20

### ✨ Nouvelles fonctionnalités majeures

#### Dirty Tracking (Suivi des modifications) ⭐ NOUVEAU
- **Système de tracking automatique des modifications** dans `DirectusModel`
  - Tracking transparent : Les getters retournent toujours les valeurs actuelles (originales ou modifiées)
  - Stockage à trois niveaux :
    - `_data` : État actuel (mutable)
    - `_originalData` : État initial (immutable)
    - `_dirtyFields` : Set des champs modifiés
  - Tous les setters (17 méthodes) trackent automatiquement les modifications via `_dirtyFields.add(key)`
  
- **Nouvelle méthode `toJsonDirty()`** ⭐
  - Retourne uniquement les champs modifiés (optimisation des UPDATE)
  - Extraction automatique des IDs pour les relations Many-to-One
  - Extraction automatique des listes d'IDs pour les relations Many-to-Many
  - Détection intelligente des objets relationnels (vérifie la présence de clé `id`)
  - Réduit considérablement la bande passante lors des mises à jour
  
- **API de gestion du tracking**
  - `isDirty` : Getter booléen pour vérifier si le modèle a été modifié
  - `isDirtyField(String key)` : Vérifier si un champ spécifique est modifié
  - `dirtyFields` : Getter retournant le Set des noms de champs modifiés
  - `markClean()` : Marquer le modèle comme propre après sauvegarde (synchronise `_originalData` avec `_data`)
  - `revert()` : Annuler toutes les modifications (rollback vers `_originalData`)
  - `getOriginalValue(String key)` : Obtenir la valeur originale d'un champ avant modification
  
- **Comportement transparent**
  - Getters : Retournent toujours `_data[key]` (valeur actuelle, modifiée ou non)
  - Setters : Mettent à jour `_data[key]` ET ajoutent `key` à `_dirtyFields`
  - Lecture immédiate des modifications : `user.firstName.set('Jean')` → `user.firstName.value` retourne `'Jean'`
  - Aucune intervention manuelle requise : Tracking automatique dans tous les setters
  
- **Avantages**
  - ✅ Optimisation réseau : UPDATE envoie uniquement les modifications
  - ✅ Clarté : `toJson()` pour CREATE complet, `toJsonDirty()` pour UPDATE partiel
  - ✅ Gestion d'état : `revert()`, `markClean()`, `isDirty` pour contrôle complet
  - ✅ Relations intelligentes : Conversion automatique objets → IDs
  - ✅ Debuggable : `dirtyFields`, `getOriginalValue()` pour inspection
  - ✅ Zero breaking changes : Backward compatible avec code existant

- **Documentation et exemples**
  - Section complète dans README.md avec 8 exemples d'utilisation
  - Fichier d'exemple dédié : `example/dirty_tracking_example.dart`
  - Workflow complet : GET → MODIFY → UPDATE avec `toJsonDirty()` → `markClean()`

### 🔄 Modifications

- **Constructeurs `DirectusModel`**
  - Constructeur principal : Copie `data` dans `_originalData` pour tracking initial
  - Constructeur `empty()` : Initialise `_originalData` à `{}` (nouveau modèle sans état initial)

## [0.2.0] - 2024-01-15

### ✨ Nouvelles fonctionnalités majeures

#### Gestion complète des erreurs Directus ⭐ NOUVEAU
- **31 codes d'erreur officiels implémentés** avec types d'exceptions spécifiques
  - `DirectusErrorCode` enum pour tous les codes Directus
  - `DirectusException.fromJson()` factory pour mapping automatique
  - Nouveaux types d'exceptions :
    - `DirectusFileException` - Erreurs de fichiers (CONTENT_TOO_LARGE, UNSUPPORTED_MEDIA_TYPE)
    - `DirectusRateLimitException` - Rate limiting (REQUESTS_EXCEEDED, EMAIL_LIMIT_EXCEEDED)
    - `DirectusMethodNotAllowedException` - Méthode HTTP non autorisée
    - `DirectusDatabaseException` - Erreurs BDD (INVALID_FOREIGN_KEY, RECORD_NOT_UNIQUE)
    - `DirectusRangeException` - Plage invalide (RANGE_NOT_SATISFIABLE)
    - `DirectusConfigException` - Configuration (INVALID_IP, INVALID_PROVIDER)
  - Accès aux extensions Directus (code d'erreur, informations supplémentaires)
  - Mapping intelligent selon le code d'erreur dans `DirectusHttpClient`

#### Agrégations et statistiques ⭐ NOUVEAU
- **Système d'agrégation type-safe** avec API fluide
  - 9 opérations : `count`, `countDistinct`, `countAll`, `sum`, `sumDistinct`, `avg`, `avgDistinct`, `min`, `max`
  - `Aggregate` class avec méthodes chaînables
  - `GroupBy` pour regroupements par champs
  
- **Fonctions de date/temps**
  - 9 fonctions : `year`, `month`, `week`, `day`, `weekday`, `hour`, `minute`, `second`, `count`
  - `Func` class pour utilisation dans filtres et groupBy
  
- **Variables dynamiques**
  - 4 variables système : `$NOW`, `$CURRENT_USER`, `$CURRENT_ROLE`, `$CURRENT_POLICIES`
  - `DynamicVar` class avec constantes statiques
  - Utilisation dans filtres pour contexte utilisateur

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
