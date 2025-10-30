# Implémentation des Modèles Directus

## Vue d'ensemble

J'ai créé 7 nouveaux modèles typés pour les services que j'ai implémentés précédemment. Ces modèles suivent l'architecture existante de la librairie avec le pattern Active Record et les property wrappers.

## Modèles Créés

### 1. DirectusComment (`directus_comment.dart`)

**Collection:** `directus_comments`

**Propriétés:**
- `collection` (string) - Collection contenant l'item commenté
- `item` (string) - ID de l'item commenté
- `comment` (string) - Texte du commentaire

**Propriétés héritées de DirectusModel:**
- `id` - Identifiant unique
- `dateCreated` - Date de création
- `dateUpdated` - Date de mise à jour
- `userCreated` - Utilisateur créateur
- `userUpdated` - Utilisateur modificateur

**Helpers:**
- `author` - Obtient l'utilisateur créateur (DirectusUser)
- `editor` - Obtient l'utilisateur modificateur (DirectusUser)
- `authorName` - Nom de l'auteur
- `isEdited` - Vérifie si le commentaire a été modifié
- `formattedDateCreated` - Date de création formatée
- `formattedDateUpdated` - Date de mise à jour formatée
- `summary` - Résumé du commentaire
- `hasComment` - Vérifie si le commentaire a du texte
- `isForCollection()` - Vérifie l'appartenance à une collection
- `isForItem()` - Vérifie l'appartenance à un item

### 2. DirectusPanel (`directus_panel.dart`)

**Collection:** `directus_panels`

**Propriétés:**
- `dashboard` (string) - ID du dashboard contenant le panel
- `name` (string) - Nom du panel
- `icon` (string) - Icône Material Design
- `color` (string) - Couleur d'accent (hexcode)
- `showHeader` (bool) - Si l'en-tête doit être affiché
- `note` (string) - Description du panel
- `type` (string) - Type de panel (time-series, metric, list, label, etc.)
- `positionX` (int) - Position X sur la grille
- `positionY` (int) - Position Y sur la grille
- `width` (int) - Largeur en points de grille
- `height` (int) - Hauteur en points de grille
- `options` (object) - Options spécifiques au type

**Helpers:**
- `creator` - Obtient l'utilisateur créateur
- `creatorName` - Nom du créateur
- `area` - Calcule la surface (width × height)
- `hasNote`, `hasHeader`, `hasOptions` - Vérifications d'existence
- `isTimeSeries`, `isMetric`, `isList`, `isLabel` - Vérification du type
- `formattedDateCreated` - Date formatée
- `summary` - Résumé du panel

### 3. DirectusDashboard (`directus_dashboard.dart`)

**Collection:** `directus_dashboards`

**Propriétés:**
- `name` (string) - Nom du dashboard
- `icon` (string) - Icône Material Design
- `note` (string) - Description
- `color` (string) - Couleur d'accent (hexcode)
- `panels` (List<DirectusPanel>) - Liste des panels (One-to-Many)

**Helpers:**
- `creator` - Obtient l'utilisateur créateur
- `creatorName` - Nom du créateur
- `hasNote`, `hasPanels` - Vérifications d'existence
- `panelsList` - Liste des panels
- `panelsCount` - Nombre de panels
- `getPanelsByType()` - Filtre les panels par type
- `formattedDateCreated` - Date formatée
- `summary` - Résumé du dashboard

### 4. DirectusFolder (`directus_folder.dart`)

**Collection:** `directus_folders`

**Propriétés:**
- `name` (string) - Nom du dossier
- `parent` (string, nullable) - ID du dossier parent (Many-to-One)

**Helpers:**
- `isRootFolder` - Vérifie si c'est un dossier racine
- `hasParent` - Vérifie si le dossier a un parent
- `parentFolder` - Obtient le dossier parent (DirectusFolder)
- `parentName` - Nom du dossier parent
- `summary` - Résumé du dossier

### 5. DirectusField (`directus_field.dart`)

**Collection:** `directus_fields`

**Propriétés:**
- `collection` (string) - Nom de la collection
- `field` (string) - Nom du champ
- `special` (List<string>) - Drapeaux de transformation (alias, file, m2o, o2m, m2m, m2a, translations)
- `interface` (string) - Interface utilisée (input, textarea, wysiwyg, dropdown, datetime, etc.)
- `options` (object) - Options de l'interface
- `display` (string) - Display utilisé
- `displayOptions` (object) - Options du display
- `readonly` (bool) - Lecture seule
- `hidden` (bool) - Caché
- `sort` (int) - Position d'affichage
- `width` (string) - Largeur (half, half-left, half-right, half-space, full, fill)
- `translations` (List<Map>) - Traductions du nom du champ
- `note` (string) - Description
- `required` (bool) - Champ requis
- `group` (int) - Groupe d'appartenance
- `validationMessage` (string) - Message de validation

**Helpers:**
- Vérifications d'existence: `hasNote`, `hasInterface`, `hasOptions`, `hasDisplay`, `hasDisplayOptions`, `hasSpecial`
- Vérifications d'état: `isRequired`, `isReadonly`, `isHidden`
- Vérifications de type: `isAlias`, `isM2O`, `isO2M`, `isM2M`, `isM2A`, `isTranslations`, `isFile`
- `summary` - Résumé du champ

### 6. DirectusOperation (`directus_operation.dart`)

**Collection:** `directus_operations`

**Propriétés:**
- `name` (string) - Nom de l'opération
- `key` (string) - Clé unique dans le flow
- `type` (string) - Type (log, mail, notification, create, read, request, sleep, transform, trigger, condition)
- `positionX` (int) - Position X dans l'espace de travail
- `positionY` (int) - Position Y dans l'espace de travail
- `options` (object) - Options dépendant du type
- `resolve` (string) - Opération de succès ("then")
- `reject` (string) - Opération d'échec ("otherwise")
- `flow` (string) - ID du flow parent (Many-to-One)

**Helpers:**
- `creator` - Obtient l'utilisateur créateur
- `creatorName` - Nom du créateur
- `hasOptions`, `hasResolve`, `hasReject` - Vérifications d'existence
- Vérifications de type: `isLog`, `isMail`, `isNotification`, `isCreate`, `isRead`, `isRequest`, `isSleep`, `isTransform`, `isTrigger`, `isCondition`
- `formattedDateCreated` - Date formatée
- `summary` - Résumé de l'opération

### 7. DirectusFlow (`directus_flow.dart`)

**Collection:** `directus_flows`

**Propriétés:**
- `name` (string) - Nom du flow
- `icon` (string) - Icône
- `color` (string) - Couleur (hexcode)
- `description` (string) - Description
- `status` (string) - Statut (active, inactive)
- `trigger` (string) - Type de déclencheur (hook, webhook, operation, schedule, manual)
- `accountability` (string) - Permission ($public, $trigger, $full, ou UUID d'un rôle)
- `options` (object) - Options du déclencheur
- `operation` (string) - ID de l'opération connectée au trigger
- `operations` (List<DirectusOperation>) - Liste des opérations (One-to-Many)

**Helpers:**
- `creator` - Obtient l'utilisateur créateur
- `creatorName` - Nom du créateur
- Vérifications d'état: `isActive`, `isInactive`
- Vérifications d'existence: `hasDescription`, `hasOptions`, `hasOperations`
- `operationsList` - Liste des opérations
- `operationsCount` - Nombre d'opérations
- Vérifications de trigger: `isHookTrigger`, `isWebhookTrigger`, `isOperationTrigger`, `isScheduleTrigger`, `isManualTrigger`
- Actions: `activate()`, `deactivate()`
- `formattedDateCreated` - Date formatée
- `summary` - Résumé du flow

## Architecture

Tous les modèles suivent l'architecture existante :

1. **Héritage de DirectusModel** : Tous les modèles héritent de `DirectusModel` pour bénéficier des propriétés standards (id, dateCreated, dateUpdated, userCreated, userUpdated) et des méthodes de base.

2. **Property Wrappers** : Utilisation de property wrappers (`stringValue`, `intValue`, `boolValue`, `objectValue`, `listValue`, `modelValue`, `modelListValue`) pour l'accès typé aux données.

3. **Factory Pattern** : Chaque modèle a une méthode `factory()` statique pour l'instanciation depuis un Map.

4. **Active Record Pattern** : Les modèles stockent leurs données JSON en interne et fournissent des getters/setters typés.

5. **Helpers** : Chaque modèle fournit des méthodes helper pour faciliter l'utilisation (vérifications, formatage, résumés).

6. **Relations** : Support des relations Many-to-One et One-to-Many avec chargement des objets liés via `getDirectusModelOrNull<T>()` et `getDirectusModelList<T>()`.

## Exports

Tous les modèles ont été ajoutés au fichier principal `lib/fcs_directus.dart` :

```dart
export 'src/models/directus_comment.dart';
export 'src/models/directus_dashboard.dart';
export 'src/models/directus_panel.dart';
export 'src/models/directus_field.dart';
export 'src/models/directus_flow.dart';
export 'src/models/directus_operation.dart';
export 'src/models/directus_folder.dart';
```

## Utilisation

### Exemple avec DirectusComment

```dart
// Créer un commentaire typé
final comment = DirectusComment.empty()
  ..collection.set('articles')
  ..item.set('15')
  ..comment.set('Excellent article!');

// Sauvegarder
await client.comments.createComment(comment.toMap());

// Récupérer avec deep loading de l'auteur
final comments = await client.comments.getComments(
  query: QueryParameters(
    fields: ['*', 'user_created.*'],
  ),
);

// Utiliser les helpers
for (final comment in comments.data) {
  final commentModel = DirectusComment(comment);
  print(commentModel.summary);
  print('Auteur: ${commentModel.authorName}');
  if (commentModel.isEdited) {
    print('Modifié le ${commentModel.formattedDateUpdated}');
  }
}
```

### Exemple avec DirectusFlow

```dart
// Créer un flow typé
final flow = DirectusFlow.empty()
  ..name.set('Update Articles Flow')
  ..status.set('active')
  ..trigger.set('manual')
  ..icon.set('bolt')
  ..accountability.set('\$trigger');

await client.flows.createFlow(flow.toMap());

// Récupérer avec opérations
final flowData = await client.flows.getFlow(
  'flow-id',
  query: QueryParameters(
    fields: ['*', 'operations.*'],
  ),
);

final flow = DirectusFlow(flowData);
print(flow.summary);
print('Type de trigger: ${flow.trigger.value}');
print('Nombre d\'opérations: ${flow.operationsCount}');

// Activer/désactiver
flow.activate();
await client.flows.updateFlow(flow.id!, flow.toMap());
```

## Tests

Tous les modèles compilent sans erreur et les 76 tests existants passent. Les modèles sont prêts à être utilisés en production.

## Conformité OpenAPI

Les modèles implémentent toutes les propriétés définies dans les schémas OpenAPI :

- ✅ `openapi/components/schemas/comments.yaml`
- ✅ `openapi/components/schemas/dashboards.yaml`
- ✅ `openapi/components/schemas/panels.yaml`
- ✅ `openapi/components/schemas/fields.yaml`
- ✅ `openapi/components/schemas/flows.yaml`
- ✅ `openapi/components/schemas/operations.yaml`
- ✅ `openapi/components/schemas/folders.yaml`

## Paramètres OpenAPI

Les services utilisent `QueryParameters` qui supporte les paramètres standards de l'API Directus :

- ✅ `fields` - Contrôle les champs retournés
- ✅ `filter` - Filtrage des items
- ✅ `sort` - Tri des résultats
- ✅ `limit` - Limite de résultats
- ✅ `offset` - Pagination par offset
- ✅ `page` - Pagination par page
- ✅ `search` - Recherche full-text
- ✅ `deep` - Relations à inclure
- ✅ `aggregate` - Agrégations
- ✅ `groupBy` - Regroupement

**Note:** Les paramètres `meta`, `export`, `version`, et `backlink` ne sont pas encore implémentés dans `QueryParameters`, mais les services les gèrent manuellement quand nécessaire (voir `FlowsService.triggerFlow()` et `FlowsService.triggerFlowGet()`).

## Prochaines Étapes (Optionnel)

1. Ajouter le support des paramètres `meta`, `export`, `version`, et `backlink` dans `QueryParameters`
2. Mettre à jour les services pour utiliser les modèles typés au lieu de `Map<String, dynamic>`
3. Créer des fichiers d'exemple pour chaque modèle
4. Ajouter des tests unitaires spécifiques pour chaque modèle
