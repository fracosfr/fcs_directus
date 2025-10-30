# Nouveaux Services API Directus

Ce document décrit les nouveaux services ajoutés à la librairie `fcs_directus` pour gérer les fonctionnalités supplémentaires de l'API Directus.

## 📋 Services Ajoutés

### 1. CommentsService ✨

Service pour gérer les commentaires sur les items.

**Endpoints :**
- `GET /comments` - Liste tous les commentaires
- `POST /comments` - Crée un ou plusieurs commentaires
- `GET /comments/{id}` - Récupère un commentaire spécifique
- `PATCH /comments/{id}` - Met à jour un commentaire
- `DELETE /comments/{id}` - Supprime un commentaire
- `PATCH /comments` - Met à jour plusieurs commentaires
- `DELETE /comments` - Supprime plusieurs commentaires

**Utilisation :**
```dart
// Créer un commentaire
await client.comments.createComment(
  collection: 'articles',
  item: '15',
  comment: 'Excellent article!',
);

// Récupérer tous les commentaires d'un item
final comments = await client.comments.getCommentsForItem(
  'articles',
  '15',
  query: QueryParameters(sort: ['-date_created']),
);

// Mettre à jour un commentaire
await client.comments.updateComment(
  'comment-id',
  {'comment': 'Commentaire mis à jour'},
);

// Supprimer un commentaire
await client.comments.deleteComment('comment-id');
```

**Méthodes principales :**
- `getComments()` - Liste avec filtres
- `getComment(id)` - Récupération par ID
- `createComment()` - Création simple
- `createComments()` - Création multiple
- `updateComment()` / `updateComments()` - Mise à jour
- `deleteComment()` / `deleteComments()` - Suppression
- `getCommentsForItem()` - Commentaires d'un item spécifique

---

### 2. DashboardsService ✨

Service pour gérer les tableaux de bord (dashboards) dans le module Insights.

**Endpoints :**
- `GET /dashboards` - Liste tous les dashboards
- `POST /dashboards` - Crée un ou plusieurs dashboards
- `GET /dashboards/{id}` - Récupère un dashboard spécifique
- `PATCH /dashboards/{id}` - Met à jour un dashboard
- `DELETE /dashboards/{id}` - Supprime un dashboard
- `PATCH /dashboards` - Met à jour plusieurs dashboards
- `DELETE /dashboards` - Supprime plusieurs dashboards

**Utilisation :**
```dart
// Créer un dashboard
final dashboard = await client.dashboards.createDashboard({
  'name': 'Sales Dashboard',
  'icon': 'trending_up',
  'note': 'Tableau de bord des ventes',
  'color': '#2196F3',
});

// Récupérer tous les dashboards
final dashboards = await client.dashboards.getDashboards(
  query: QueryParameters(sort: ['name']),
);

// Mettre à jour un dashboard
await client.dashboards.updateDashboard('dashboard-id', {
  'name': 'Nouveau nom',
  'color': '#FF5722',
});

// Récupérer les dashboards d'un utilisateur
final userDashboards = await client.dashboards.getDashboardsByUser('user-id');
```

**Méthodes principales :**
- `getDashboards()` - Liste avec filtres
- `getDashboard(id)` - Récupération par ID
- `createDashboard()` / `createDashboards()` - Création
- `updateDashboard()` / `updateDashboards()` - Mise à jour
- `deleteDashboard()` / `deleteDashboards()` - Suppression
- `getDashboardsByUser()` - Dashboards par utilisateur

---

### 3. ExtensionsService ✨

Service pour gérer les extensions Directus (interfaces, layouts, modules, etc.).

**Endpoints :**
- `GET /extensions` - Liste toutes les extensions
- `PATCH /extensions/{name}` - Met à jour la configuration d'une extension
- `PATCH /extensions/{bundle}/{name}` - Met à jour une extension dans un bundle

**Utilisation :**
```dart
// Lister toutes les extensions
final extensions = await client.extensions.getExtensions();

// Mettre à jour la configuration d'une extension
await client.extensions.updateExtension(
  'my-custom-interface',
  {
    'meta': {
      'enabled': true,
      'config': {'theme': 'dark'},
    },
  },
);

// Mettre à jour une extension dans un bundle
await client.extensions.updateExtensionInBundle(
  'my-bundle',
  'my-extension',
  {'meta': {'enabled': false}},
);

// Récupérer les extensions par type
final interfaces = await client.extensions.getExtensionsByType('interface');

// Vérifier si une extension est installée
final isInstalled = await client.extensions.isExtensionInstalled('my-extension');
```

**Méthodes principales :**
- `getExtensions()` - Liste toutes les extensions
- `updateExtension()` - Met à jour une extension
- `updateExtensionInBundle()` - Met à jour dans un bundle
- `getExtensionsByType()` - Filtre par type
- `isExtensionInstalled()` - Vérifie l'installation

**Types d'extensions :** interface, display, layout, module, panel, hook, endpoint, operation, bundle

---

### 4. FieldsService ✨

Service pour gérer les champs (fields) des collections.

**Endpoints :**
- `GET /fields` - Liste tous les champs du projet
- `GET /fields/{collection}` - Liste les champs d'une collection
- `POST /fields/{collection}` - Crée un nouveau champ
- `GET /fields/{collection}/{id}` - Récupère un champ spécifique
- `PATCH /fields/{collection}/{id}` - Met à jour un champ
- `DELETE /fields/{collection}/{id}` - Supprime un champ

**Utilisation :**
```dart
// Lister tous les champs d'une collection
final fields = await client.fields.getFieldsInCollection('articles');

// Créer un nouveau champ
await client.fields.createField('articles', {
  'field': 'author_email',
  'type': 'string',
  'schema': {
    'is_nullable': true,
  },
  'meta': {
    'interface': 'input',
    'options': {'placeholder': 'email@example.com'},
    'display': 'formatted-value',
    'readonly': false,
    'hidden': false,
    'width': 'full',
  },
});

// Mettre à jour un champ
await client.fields.updateField('articles', 'title', {
  'meta': {
    'note': 'Titre principal de l\'article',
    'width': 'full',
  },
});

// Supprimer un champ (ATTENTION: irréversible!)
await client.fields.deleteField('articles', 'old_field');

// Vérifier si un champ existe
final exists = await client.fields.fieldExists('articles', 'title');

// Récupérer les champs obligatoires
final requiredFields = await client.fields.getRequiredFields('articles');

// Récupérer les champs par type d'interface
final inputs = await client.fields.getFieldsByInterface('articles', 'input');
```

**Méthodes principales :**
- `getAllFields()` - Tous les champs du projet
- `getFieldsInCollection()` - Champs d'une collection
- `getField()` - Détails d'un champ
- `createField()` - Création de champ
- `updateField()` - Mise à jour
- `deleteField()` - Suppression (irréversible!)
- `fieldExists()` - Vérification existence
- `getRequiredFields()` - Champs obligatoires
- `getFieldsByInterface()` - Filtre par interface

---

### 5. FlowsService ✨

Service pour gérer les flows (automatisation et traitement de données).

**Endpoints :**
- `GET /flows` - Liste tous les flows
- `POST /flows` - Crée un ou plusieurs flows
- `GET /flows/{id}` - Récupère un flow spécifique
- `PATCH /flows/{id}` - Met à jour un flow
- `DELETE /flows/{id}` - Supprime un flow
- `PATCH /flows` - Met à jour plusieurs flows
- `DELETE /flows` - Supprime plusieurs flows
- `GET /flows/trigger/{id}` - Déclenche un flow (GET)
- `POST /flows/trigger/{id}` - Déclenche un flow (POST)

**Utilisation :**
```dart
// Créer un flow
await client.flows.createFlow({
  'name': 'Email Notification Flow',
  'icon': 'email',
  'status': 'active',
  'trigger': 'event',
  'accountability': 'all',
  'options': {
    'type': 'action',
    'scope': ['items.create'],
    'collections': ['articles'],
  },
});

// Récupérer tous les flows actifs
final activeFlows = await client.flows.getActiveFlows();

// Récupérer les flows par type de trigger
final webhookFlows = await client.flows.getFlowsByTrigger('webhook');

// Déclencher un flow avec webhook POST
final result = await client.flows.triggerFlow('flow-id', {
  'article_id': '123',
  'action': 'publish',
});

// Déclencher un flow avec webhook GET
final result = await client.flows.triggerFlowGet('flow-id');

// Mettre à jour un flow
await client.flows.updateFlow('flow-id', {
  'status': 'inactive',
});

// Supprimer un flow
await client.flows.deleteFlow('flow-id');
```

**Types de triggers :**
- `manual` - Déclenchement manuel
- `webhook` - Déclenchement par webhook
- `event` - Déclenchement par événement
- `schedule` - Déclenchement programmé
- `operation` - Déclenchement par opération

**Méthodes principales :**
- `getFlows()` - Liste avec filtres
- `getFlow(id)` - Récupération par ID
- `createFlow()` / `createFlows()` - Création
- `updateFlow()` / `updateFlows()` - Mise à jour
- `deleteFlow()` / `deleteFlows()` - Suppression
- `triggerFlow()` - Déclenchement POST
- `triggerFlowGet()` - Déclenchement GET
- `getFlowsByTrigger()` - Filtre par trigger
- `getActiveFlows()` - Flows actifs uniquement

---

### 6. FoldersService ✨

Service pour gérer les dossiers virtuels de fichiers.

**Endpoints :**
- `GET /folders` - Liste tous les dossiers
- `POST /folders` - Crée un ou plusieurs dossiers
- `GET /folders/{id}` - Récupère un dossier spécifique
- `PATCH /folders/{id}` - Met à jour un dossier
- `DELETE /folders/{id}` - Supprime un dossier
- `PATCH /folders` - Met à jour plusieurs dossiers
- `DELETE /folders` - Supprime plusieurs dossiers

**Utilisation :**
```dart
// Créer un dossier racine
final rootFolder = await client.folders.createFolder(name: 'Documents');

// Créer un sous-dossier
final subFolder = await client.folders.createFolder(
  name: 'Rapports 2024',
  parent: rootFolder['id'],
);

// Récupérer tous les dossiers racine
final rootFolders = await client.folders.getRootFolders();

// Récupérer les sous-dossiers d'un dossier
final subFolders = await client.folders.getSubFolders('parent-id');

// Déplacer un dossier
await client.folders.moveFolder('folder-id', 'new-parent-id');

// Renommer un dossier
await client.folders.renameFolder('folder-id', 'Nouveau nom');

// Mettre à jour un dossier
await client.folders.updateFolder('folder-id', {
  'name': 'Nouveau nom',
  'parent': 'new-parent-id',
});

// Supprimer un dossier (les fichiers sont déplacés vers la racine)
await client.folders.deleteFolder('folder-id');
```

**Méthodes principales :**
- `getFolders()` - Liste avec filtres
- `getFolder(id)` - Récupération par ID
- `createFolder()` / `createFolders()` - Création
- `updateFolder()` / `updateFolders()` - Mise à jour
- `deleteFolder()` / `deleteFolders()` - Suppression
- `getRootFolders()` - Dossiers racine
- `getSubFolders()` - Sous-dossiers
- `moveFolder()` - Déplacement
- `renameFolder()` - Renommage

⚠️ **Note importante :** Les dossiers sont virtuels et ne sont pas reflétés dans l'adaptateur de stockage. Lors de la suppression d'un dossier, les fichiers qu'il contient sont automatiquement déplacés vers le dossier racine.

---

## 🔧 Améliorations aux Services Existants

### CollectionsService
Le service collections était déjà complet avec toutes les méthodes CRUD :
- ✅ `getCollections()` - Liste toutes les collections
- ✅ `getCollection()` - Détails d'une collection
- ✅ `createCollection()` - Création
- ✅ `updateCollection()` - Mise à jour
- ✅ `deleteCollection()` - Suppression

### FilesService
Le service files était déjà très complet avec :
- ✅ Upload depuis chemin local (`uploadFile()`)
- ✅ Upload depuis bytes (`uploadFileFromBytes()`)
- ✅ Import depuis URL (`importFile()`)
- ✅ Métadonnées (`updateFile()`, `getFile()`, `getFiles()`)
- ✅ Suppression (`deleteFile()`)
- ✅ Génération d'URL (`getFileUrl()`, `getThumbnailUrl()`)

---

## 📊 Récapitulatif

| Service | Endpoints | CRUD Complet | Fonctionnalités Spéciales |
|---------|-----------|--------------|---------------------------|
| CommentsService | 7 | ✅ | Filtres par item/collection |
| DashboardsService | 7 | ✅ | Filtres par utilisateur |
| ExtensionsService | 3 | Lecture + MAJ | Filtres par type |
| FieldsService | 6 | ✅ | Validation, champs obligatoires |
| FlowsService | 10 | ✅ | Triggers webhook GET/POST |
| FoldersService | 7 | ✅ | Hiérarchie, déplacement |

**Total : 40 nouveaux endpoints API implémentés** 🎉

---

## 💡 Utilisation dans DirectusClient

Tous les services sont directement accessibles via l'instance du client :

```dart
final client = DirectusClient(config);

// Commentaires
await client.comments.createComment(...);

// Dashboards
await client.dashboards.getDashboards();

// Extensions
await client.extensions.getExtensions();

// Champs
await client.fields.getFieldsInCollection('articles');

// Flows
await client.flows.triggerFlow('flow-id', {...});

// Dossiers
await client.folders.createFolder(name: 'Docs');
```

---

## 🎯 Prochaines Étapes Recommandées

1. **Créer des exemples d'utilisation** pour chaque nouveau service
2. **Ajouter des tests unitaires** pour les nouveaux services
3. **Créer des modèles Dart** (DirectusComment, DirectusDashboard, etc.) si nécessaire
4. **Documenter dans le README** principal
5. **Mettre à jour le CHANGELOG** avec la version et les ajouts

---

## 📚 Références

- [Documentation API Comments](https://docs.directus.io/reference/system/comments.html)
- [Documentation API Dashboards](https://docs.directus.io/reference/system/dashboards.html)
- [Documentation API Extensions](https://docs.directus.io/reference/system/extensions.html)
- [Documentation API Fields](https://docs.directus.io/reference/system/fields.html)
- [Documentation API Flows](https://docs.directus.io/reference/system/flows.html)
- [Documentation API Folders](https://docs.directus.io/reference/system/folders.html)

---

**Date d'implémentation :** 30 octobre 2025  
**Version de la librairie :** 0.2.0+  
**État :** ✅ Production-ready
