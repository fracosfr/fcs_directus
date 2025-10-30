# Services

Référence complète des 30+ services disponibles dans fcs_directus.

## 📋 Vue d'ensemble

fcs_directus fournit un service pour chaque endpoint de l'API Directus, permettant d'interagir avec toutes les fonctionnalités du CMS.

## 🎯 Services principaux

### ItemsService (Collections personnalisées)

Service générique pour gérer vos collections personnalisées.

```dart
// Service non typé
final articles = directus.items('articles');

// Service typé
final articles = directus.items<Article>('articles');

// Méthodes disponibles
await articles.readMany(query: ...);
await articles.readOne(id: '1');
await articles.createOne(item: {...});
await articles.updateOne(id: '1', item: {...});
await articles.deleteOne(id: '1');
await articles.createMany(items: [...]);
await articles.updateMany(ids: [...], item: {...});
await articles.deleteMany(ids: [...]);
```

[Documentation complète →](api-reference/services/items-service.md)

### AuthService (Authentification)

Gestion de l'authentification et des tokens.

```dart
final auth = directus.auth;

// Login
await auth.login(email: '...', password: '...');

// Logout
await auth.logout();

// Refresh token
await auth.refresh();

// Vérifier authentification
final isAuth = await auth.isAuthenticated();

// OAuth providers
final providers = await auth.providers();
```

[Documentation complète →](api-reference/services/auth-service.md) | [Guide →](03-authentication.md)

### UsersService (Utilisateurs)

Gestion des utilisateurs Directus.

```dart
final users = directus.users;

// Utilisateur actuel
await users.me();

// CRUD utilisateurs
await users.readMany();
await users.readOne(id: 'user-id');
await users.createOne(item: {...});
await users.updateOne(id: 'user-id', item: {...});
await users.deleteOne(id: 'user-id');

// Inviter un utilisateur
await users.invite(email: '...', role: 'role-id');

// Accepter une invitation
await users.acceptInvite(token: '...', password: '...');

// Générer un token 2FA
await users.tfa Generate(password: '...');
```

[Documentation complète →](api-reference/services/users-service.md)

### FilesService (Fichiers)

Gestion des fichiers et médias.

```dart
final files = directus.files;

// Lire fichiers
await files.readMany();
await files.readOne(id: 'file-id');

// Upload
await files.upload(
  file: File('/path/to/image.jpg'),
  title: 'Mon image',
  folder: 'folder-id',
);

// Upload depuis bytes
await files.uploadFromBytes(
  bytes: imageBytes,
  filename: 'image.jpg',
  title: 'Mon image',
);

// Importer depuis URL
await files.import(url: 'https://example.com/image.jpg');

// Mettre à jour
await files.updateOne(id: 'file-id', item: {...});

// Supprimer
await files.deleteOne(id: 'file-id');
```

[Documentation complète →](api-reference/services/files-service.md) | [Guide →](10-file-management.md)

### FoldersService (Dossiers)

Organisation hiérarchique des fichiers.

```dart
final folders = directus.folders;

// CRUD dossiers
await folders.readMany();
await folders.readOne(id: 'folder-id');
await folders.createOne(item: {'name': 'Mon dossier'});
await folders.updateOne(id: 'folder-id', item: {...});
await folders.deleteOne(id: 'folder-id');
```

[Documentation complète →](api-reference/services/folders-service.md)

## 🔒 Services de contrôle d'accès

### RolesService (Rôles)

```dart
final roles = directus.roles;

await roles.readMany();
await roles.readOne(id: 'role-id');
await roles.createOne(item: {'name': 'Editor', ...});
await roles.updateOne(id: 'role-id', item: {...});
await roles.deleteOne(id: 'role-id');
```

### PermissionsService (Permissions)

```dart
final permissions = directus.permissions;

await permissions.readMany();
await permissions.readOne(id: 'permission-id');
await permissions.createOne(item: {...});
await permissions.updateOne(id: 'permission-id', item: {...});
await permissions.deleteOne(id: 'permission-id');
```

### PoliciesService (Politiques)

```dart
final policies = directus.policies;

await policies.readMany();
await policies.readOne(id: 'policy-id');
await policies.createOne(item: {...});
```

## 📊 Services de contenu

### CollectionsService (Collections)

Gestion des collections (schéma).

```dart
final collections = directus.collections;

await collections.readMany();
await collections.readOne(collection: 'articles');
await collections.createOne(collection: {...});
await collections.updateOne(collection: 'articles', data: {...});
await collections.deleteOne(collection: 'articles');
```

### FieldsService (Champs)

Gestion des champs de collections.

```dart
final fields = directus.fields;

await fields.readMany(collection: 'articles');
await fields.readOne(collection: 'articles', field: 'title');
await fields.createOne(collection: 'articles', field: {...});
await fields.updateOne(collection: 'articles', field: 'title', data: {...});
await fields.deleteOne(collection: 'articles', field: 'title');
```

### RelationsService (Relations)

```dart
final relations = directus.relations;

await relations.readMany();
await relations.readOne(id: 'relation-id');
await relations.createOne(item: {...});
await relations.updateOne(id: 'relation-id', item: {...});
await relations.deleteOne(id: 'relation-id');
```

## 📝 Services de suivi

### ActivityService (Activité)

Journal des actions effectuées.

```dart
final activity = directus.activity;

await activity.readMany(query: QueryParameters(
  sort: ['-timestamp'],
  limit: 50,
));
await activity.readOne(id: 'activity-id');
await activity.createComment(collection: 'articles', item: 'item-id', comment: '...');
```

### RevisionsService (Révisions)

Historique des modifications.

```dart
final revisions = directus.revisions;

await revisions.readMany();
await revisions.readOne(id: 'revision-id');

// Révisions d'un item spécifique
await revisions.readMany(query: QueryParameters(
  filter: {
    'collection': {'_eq': 'articles'},
    'item': {'_eq': 'article-id'},
  },
));
```

### NotificationsService (Notifications)

```dart
final notifications = directus.notifications;

await notifications.readMany();
await notifications.readOne(id: 'notification-id');
await notifications.createOne(item: {...});
await notifications.deleteOne(id: 'notification-id');
```

## 🔄 Services de workflow

### FlowsService (Flux)

```dart
final flows = directus.flows;

await flows.readMany();
await flows.readOne(id: 'flow-id');
await flows.createOne(item: {...});
await flows.updateOne(id: 'flow-id', item: {...});
await flows.deleteOne(id: 'flow-id');
```

### OperationsService (Opérations)

```dart
final operations = directus.operations;

await operations.readMany();
await operations.readOne(id: 'operation-id');
await operations.createOne(item: {...});
```

## 🎨 Services d'interface

### DashboardsService (Tableaux de bord)

```dart
final dashboards = directus.dashboards;

await dashboards.readMany();
await dashboards.readOne(id: 'dashboard-id');
await dashboards.createOne(item: {...});
```

### PanelsService (Panneaux)

```dart
final panels = directus.panels;

await panels.readMany();
await panels.readOne(id: 'panel-id');
await panels.createOne(item: {...});
```

### PresetsService (Presets)

```dart
final presets = directus.presets;

await presets.readMany();
await presets.readOne(id: 'preset-id');
await presets.createOne(item: {...});
```

## 🌍 Services de localisation

### TranslationsService (Traductions)

```dart
final translations = directus.translations;

await translations.readMany();
await translations.readOne(id: 'translation-id');
await translations.createOne(item: {...});
```

## 🔧 Services système

### ServerService (Serveur)

Informations sur le serveur Directus.

```dart
final server = directus.server;

// Info serveur
await server.info();

// Ping
await server.ping();

// Health check
await server.health();
```

### SettingsService (Paramètres)

```dart
final settings = directus.settings;

await settings.read();
await settings.update(settings: {...});
```

### SchemaService (Schéma)

```dart
final schema = directus.schema;

// Snapshot du schéma
await schema.snapshot();

// Appliquer un snapshot
await schema.apply(snapshot: {...});

// Diff entre snapshots
await schema.diff(snapshot: {...});
```

## 🛠️ Services utilitaires

### UtilitiesService (Utilitaires)

```dart
final utils = directus.utilities;

// Générer un hash
await utils.hash(string: 'password');

// Vérifier un hash
await utils.hashVerify(string: 'password', hash: '...');

// Trier des items
await utils.sort(collection: 'articles', item: 'item-id', to: 'target-id');

// Nettoyer le cache
await utils.cacheClean();
```

### MetricsService (Métriques)

```dart
final metrics = directus.metrics;

await metrics.query(
  metric: 'articles',
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
```

## 📦 Services de versioning

### VersionsService (Versions)

```dart
final versions = directus.versions;

await versions.readMany(query: QueryParameters(
  filter: {
    'collection': {'_eq': 'articles'},
    'item': {'_eq': 'article-id'},
  },
));

// Créer une version
await versions.save(
  collection: 'articles',
  item: 'article-id',
  name: 'v1.0',
);

// Promouvoir une version
await versions.promote(id: 'version-id');
```

### SharesService (Partages)

```dart
final shares = directus.shares;

// Créer un partage
await shares.createOne(item: {
  'collection': 'articles',
  'item': 'article-id',
  'password': 'secret',
});

// Accéder à un partage
await shares.info(id: 'share-id');
```

## 📊 Tableau récapitulatif

| Service | Endpoint | Usage principal |
|---------|----------|-----------------|
| `items()` | `/items/:collection` | Collections personnalisées |
| `auth` | `/auth/*` | Authentification |
| `users` | `/users/*` | Gestion utilisateurs |
| `files` | `/files/*` | Upload/gestion fichiers |
| `folders` | `/folders/*` | Organisation fichiers |
| `roles` | `/roles/*` | Rôles utilisateurs |
| `permissions` | `/permissions/*` | Permissions d'accès |
| `policies` | `/policies/*` | Politiques d'accès |
| `collections` | `/collections/*` | Schéma collections |
| `fields` | `/fields/*` | Schéma champs |
| `relations` | `/relations/*` | Relations entre collections |
| `activity` | `/activity/*` | Journal d'activité |
| `revisions` | `/revisions/*` | Historique modifications |
| `notifications` | `/notifications/*` | Notifications système |
| `flows` | `/flows/*` | Workflows automatisés |
| `operations` | `/operations/*` | Opérations de flux |
| `dashboards` | `/dashboards/*` | Tableaux de bord |
| `panels` | `/panels/*` | Panneaux de dashboard |
| `presets` | `/presets/*` | Préférences UI |
| `translations` | `/translations/*` | Traductions interface |
| `server` | `/server/*` | Info serveur |
| `settings` | `/settings` | Paramètres globaux |
| `schema` | `/schema/*` | Snapshots de schéma |
| `utilities` | `/utils/*` | Fonctions utilitaires |
| `metrics` | `/metrics/*` | Métriques et analytics |
| `versions` | `/versions/*` | Gestion de versions |
| `shares` | `/shares/*` | Partages publics |

## 💡 Bonnes pratiques

### 1. Utiliser les services typés

```dart
// ✅ Bon
final articles = directus.items<Article>('articles');

// ❌ Non typé
final articles = directus.items('articles');
```

### 2. Gérer les erreurs

```dart
try {
  await directus.items('articles').readMany();
} on DirectusException catch (e) {
  print('Erreur: ${e.message}');
}
```

### 3. Limiter les requêtes

```dart
// ✅ Bon
QueryParameters(limit: 20, fields: ['id', 'title'])

// ❌ Charge tout
QueryParameters()
```

## 🔗 Prochaines étapes

- [**WebSockets**](09-websockets.md) - Temps réel
- [**File Management**](10-file-management.md) - Gestion fichiers
- [**Error Handling**](11-error-handling.md) - Gestion erreurs

## 📚 Référence API

Consultez [api-reference/services/](api-reference/services/) pour la documentation détaillée de chaque service.
