# API Quick Reference - fcs_directus

Guide de référence rapide pour utiliser la librairie fcs_directus sans lire la documentation complète.

> 📌 **Pour les IA et développeurs** : Ce fichier liste toutes les fonctions disponibles avec leur signature et un exemple d'utilisation minimal.

---

## 📦 Installation

```yaml
dependencies:
  fcs_directus: ^1.0.0
```

```dart
import 'package:fcs_directus/fcs_directus.dart';
```

---

## 🔧 Configuration & Client

### DirectusClient

```dart
// Créer un client
final client = DirectusClient(DirectusConfig(
  baseUrl: 'https://directus.example.com',
  timeout: Duration(seconds: 30),
  enableLogging: false,
));

// Libérer les ressources
client.dispose();
```

### DirectusConfig

```dart
DirectusConfig({
  required String baseUrl,
  Duration timeout = const Duration(seconds: 30),
  bool enableLogging = false,
  Map<String, String>? headers,
});

// Copier avec modifications
config.copyWith(baseUrl: 'new-url', enableLogging: true);
```

---

## 🔐 Authentification (AuthService)

Accès : `client.auth`

### Login/Logout

```dart
// Login avec email/password
AuthResponse response = await client.auth.login(
  email: 'user@example.com',
  password: 'password',
  otp: '123456', // Optionnel pour 2FA
  mode: AuthMode.json, // json (défaut), cookie, session
);

// Login avec token statique
await client.auth.loginWithToken('your-static-token');

// Refresh token
AuthResponse response = await client.auth.refresh(
  refreshToken: 'optional-token',
  mode: AuthMode.json,
);

// Logout
await client.auth.logout(mode: AuthMode.json);

// Vérifier si authentifié
bool isAuth = client.auth.isAuthenticated;
String? token = client.auth.accessToken;
```

### Mot de passe

```dart
// Demander réinitialisation
await client.auth.requestPasswordReset(
  'user@example.com',
  resetUrl: 'https://app.com/reset', // Optionnel
);

// Réinitialiser
await client.auth.resetPassword(
  token: 'token-from-email',
  password: 'new-password',
);
```

### OAuth

```dart
// Lister les providers
List<OAuthProvider> providers = await client.auth.listOAuthProviders();

// Obtenir URL OAuth
String url = client.auth.getOAuthUrl(
  'google',
  redirect: 'https://app.com/callback',
);

// Login OAuth (après callback)
AuthResponse response = await client.auth.loginWithOAuth(
  provider: 'google',
  code: 'auth-code',
  state: 'optional-state',
  mode: AuthMode.json,
);
```

---

## 📦 Items (CRUD) - ItemsService

Accès : `client.items('collection_name')`

### Read (Lecture)

```dart
// Lire plusieurs items
DirectusResponse<dynamic> response = await client.items('articles').readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'status'],
    filter: Filter.field('status').equals('published'),
    sort: ['-date_created'],
    limit: 10,
    offset: 0,
    search: 'keyword',
  ),
);

// Accéder aux données
List<dynamic> items = response.data;
Meta? meta = response.meta;

// Lire un item
Map<String, dynamic> item = await client.items('articles').readOne(
  'item-id',
  query: QueryParameters(fields: ['*']),
);
```

### Create (Création)

```dart
// Créer un item
Map<String, dynamic> newItem = await client.items('articles').createOne(
  {
    'title': 'Mon article',
    'content': 'Contenu',
    'status': 'draft',
  },
  query: QueryParameters(fields: ['id', 'title']),
);

// Créer plusieurs items
List<dynamic> items = await client.items('articles').createMany([
  {'title': 'Article 1'},
  {'title': 'Article 2'},
]);
```

### Update (Mise à jour)

```dart
// Mettre à jour un item
Map<String, dynamic> updated = await client.items('articles').updateOne(
  'item-id',
  {'title': 'Nouveau titre'},
  query: QueryParameters(fields: ['*']),
);

// Mettre à jour plusieurs items
List<dynamic> updated = await client.items('articles').updateMany(
  ['id1', 'id2'],
  {'status': 'published'},
);
```

### Delete (Suppression)

```dart
// Supprimer un item
await client.items('articles').deleteOne('item-id');

// Supprimer plusieurs items
await client.items('articles').deleteMany(['id1', 'id2']);
```

---

## 🔍 Filtres (Filter)

### Opérateurs de comparaison

```dart
Filter.field('status').equals('published')
Filter.field('price').notEquals(0)
Filter.field('age').greaterThan(18)
Filter.field('age').greaterThanOrEqual(18)
Filter.field('age').lessThan(65)
Filter.field('age').lessThanOrEqual(65)
Filter.field('price').between(10, 100)
Filter.field('price').notBetween(10, 100)
```

### Opérateurs de liste

```dart
Filter.field('status').isIn(['draft', 'published'])
Filter.field('status').notIn(['archived', 'deleted'])
```

### Opérateurs NULL

```dart
Filter.field('deleted_at').isNull()
Filter.field('deleted_at').isNotNull()
```

### Opérateurs de chaîne

```dart
Filter.field('title').contains('Directus')
Filter.field('title').notContains('spam')
Filter.field('title').startsWith('How to')
Filter.field('title').notStartsWith('Draft')
Filter.field('email').endsWith('@example.com')
Filter.field('email').notEndsWith('@spam.com')
```

### Opérateurs logiques

```dart
Filter.and([
  Filter.field('status').equals('published'),
  Filter.field('views').greaterThan(1000),
])

Filter.or([
  Filter.field('priority').equals('high'),
  Filter.field('urgent').equals(true),
])

Filter.not(Filter.field('status').equals('draft'))
```

### Relations

```dart
Filter.relation('author', Filter.field('name').equals('John'))
Filter.some('comments', Filter.field('approved').equals(true))
Filter.none('tags', Filter.field('name').equals('spam'))
```

---

## 🔗 Relations (Deep)

```dart
QueryParameters(
  deep: Deep()
    // Charger la relation author avec certains champs
    .field('author', fields: ['id', 'name', 'email'])
    
    // Charger les commentaires avec filtre et limite
    .field('comments', 
      fields: ['id', 'text', 'user'],
      filter: Filter.field('approved').equals(true),
      limit: 5,
      sort: ['-date_created'],
    )
    
    // Charger les tags
    .field('tags', fields: ['name', 'color'])
    
    // Relations imbriquées (author → avatar)
    .field('author', 
      fields: ['name'],
      deep: Deep().field('avatar', fields: ['id', 'url'])
    ),
)
```

---

## 📊 Agrégations (Aggregate)

```dart
QueryParameters(
  aggregate: Aggregate()
    .count('id')
    .sum('price')
    .avg('rating')
    .min('date_created')
    .max('date_created')
    .countDistinct('user_id'),
  
  // Grouper par
  groupBy: ['category', 'status'],
)
```

---

## 👤 Users (UsersService)

Accès : `client.users`

### CRUD

```dart
// Lire tous les utilisateurs
DirectusResponse<dynamic> users = await client.users.getUsers(
  query: QueryParameters(fields: ['id', 'email', 'first_name']),
);

// Lire un utilisateur
Map<String, dynamic> user = await client.users.getUser('user-id');

// Utilisateur actuel
DirectusUser me = await client.users.me();
DirectusUser updated = await client.users.updateMe({'first_name': 'John'});

// Créer un utilisateur
Map<String, dynamic> newUser = await client.users.createUser({
  'email': 'user@example.com',
  'password': 'password',
  'role': 'role-id',
});

// Mettre à jour
Map<String, dynamic> updated = await client.users.updateUser(
  'user-id',
  {'first_name': 'Jane'},
);

// Supprimer
await client.users.deleteUser('user-id');
```

### Invitations

```dart
// Inviter des utilisateurs
await client.users.inviteUsers(
  email: 'user@example.com', // ou ['email1', 'email2']
  roleId: 'role-id',
  inviteUrl: 'https://app.com/invite', // Optionnel
);

// Accepter une invitation
await client.users.acceptInvite(
  token: 'invite-token',
  password: 'new-password',
);
```

### Two-Factor Authentication

```dart
// Générer secret 2FA
Map<String, dynamic> tfa = await client.users.generateTwoFactorSecret(
  password: 'current-password',
);
String secret = tfa['secret'];
String otpauthUrl = tfa['otpauth_url'];

// Activer 2FA
await client.users.enableTwoFactor(
  secret: secret,
  otp: '123456',
);

// Désactiver 2FA
await client.users.disableTwoFactor(otp: '123456');
```

---

## 📁 Files (FilesService)

Accès : `client.files`

### Upload

```dart
// Upload depuis bytes
Map<String, dynamic> file = await client.files.uploadFile(
  bytes: fileBytes,
  filename: 'document.pdf',
  title: 'Mon document',
  folder: 'folder-id', // Optionnel
);

// Upload depuis chemin (non-web uniquement)
Map<String, dynamic> file = await client.files.uploadFromPath(
  filePath: '/path/to/file.jpg',
  title: 'Ma photo',
);
```

### CRUD

```dart
// Lire les fichiers
DirectusResponse<dynamic> files = await client.files.getFiles();

// Lire un fichier
Map<String, dynamic> file = await client.files.getFile('file-id');

// Mettre à jour
Map<String, dynamic> updated = await client.files.updateFile(
  'file-id',
  {'title': 'Nouveau titre'},
);

// Supprimer
await client.files.deleteFile('file-id');
```

### Import

```dart
// Importer depuis URL
Map<String, dynamic> file = await client.files.importFile(
  url: 'https://example.com/image.jpg',
  data: {'title': 'Image importée'},
);
```

---

## 🖼️ Assets (AssetsService)

Accès : `client.assets`

### Transformations d'images

```dart
// Obtenir URL avec transformations
String url = client.assets.getAssetUrl(
  'file-id',
  transforms: AssetTransform(
    width: 800,
    height: 600,
    fit: AssetFit.cover, // cover, contain, inside, outside
    quality: 80,
    format: AssetFormat.webp, // jpg, png, webp, tiff, avif
  ),
);

// Télécharger l'asset transformé
List<int> bytes = await client.assets.downloadAsset(
  'file-id',
  transforms: AssetTransform(width: 400),
);
```

### Presets

```dart
// Utiliser un preset défini
String url = client.assets.getAssetUrl(
  'file-id',
  preset: AssetPresets.thumbnail, // thumbnail, cover, small, medium, large
);
```

---

## 📚 Collections (CollectionsService)

Accès : `client.collections`

```dart
// Lire toutes les collections
List<Map<String, dynamic>> collections = await client.collections.getCollections();

// Lire une collection
Map<String, dynamic> collection = await client.collections.getCollection('articles');

// Créer une collection
Map<String, dynamic> newCollection = await client.collections.createCollection({
  'collection': 'my_collection',
  'fields': [
    {'field': 'id', 'type': 'integer', 'schema': {'is_primary_key': true}},
    {'field': 'title', 'type': 'string'},
  ],
});

// Mettre à jour
Map<String, dynamic> updated = await client.collections.updateCollection(
  'my_collection',
  {'meta': {'note': 'Updated'}},
);

// Supprimer
await client.collections.deleteCollection('my_collection');
```

---

## 🏷️ Fields (FieldsService)

Accès : `client.fields`

```dart
// Lire tous les champs d'une collection
List<Map<String, dynamic>> fields = await client.fields.getFields('articles');

// Lire un champ
Map<String, dynamic> field = await client.fields.getField('articles', 'title');

// Créer un champ
Map<String, dynamic> newField = await client.fields.createField('articles', {
  'field': 'summary',
  'type': 'text',
  'meta': {'interface': 'input-multiline'},
});

// Mettre à jour
await client.fields.updateField('articles', 'summary', {
  'meta': {'note': 'Short description'},
});

// Supprimer
await client.fields.deleteField('articles', 'summary');
```

---

## 🔗 Relations (RelationsService)

Accès : `client.relations`

```dart
// Lire toutes les relations
List<Map<String, dynamic>> relations = await client.relations.getRelations();

// Lire une relation
Map<String, dynamic> relation = await client.relations.getRelation(
  'articles',
  'author',
);

// Créer une relation Many-to-One
Map<String, dynamic> m2o = await client.relations.createRelation({
  'collection': 'articles',
  'field': 'author',
  'related_collection': 'users',
});

// Créer une relation Many-to-Many
Map<String, dynamic> m2m = await client.relations.createRelation({
  'collection': 'articles',
  'field': 'tags',
  'related_collection': 'tags',
  'meta': {'junction_field': 'tag_id'},
});

// Supprimer
await client.relations.deleteRelation('articles', 'author');
```

---

## 👮 Permissions (PermissionsService)

Accès : `client.permissions`

```dart
// Lire les permissions
DirectusResponse<dynamic> permissions = await client.permissions.readMany(
  query: QueryParameters(filter: Filter.field('role').equals('role-id')),
);

// Créer une permission
Map<String, dynamic> perm = await client.permissions.createOne({
  'role': 'role-id',
  'collection': 'articles',
  'action': 'read',
  'permissions': {},
  'fields': ['*'],
});

// Mettre à jour
await client.permissions.updateOne('perm-id', {'fields': ['id', 'title']});

// Supprimer
await client.permissions.deleteOne('perm-id');
```

---

## 🎭 Roles (RolesService)

Accès : `client.roles`

```dart
// Lire les rôles
DirectusResponse<dynamic> roles = await client.roles.getRoles();

// Créer un rôle
Map<String, dynamic> role = await client.roles.createRole({
  'name': 'Editor',
  'icon': 'supervised_user_circle',
  'description': 'Content editors',
});

// Mettre à jour
await client.roles.updateRole('role-id', {'name': 'Senior Editor'});

// Supprimer
await client.roles.deleteRole('role-id');
```

---

## 🛡️ Policies (PoliciesService)

Accès : `client.policies`

```dart
// Lire les politiques
DirectusResponse<dynamic> policies = await client.policies.readMany();

// Créer une politique
Map<String, dynamic> policy = await client.policies.createOne({
  'name': 'Read Only',
  'icon': 'lock',
  'description': 'Can only read data',
  'admin_access': false,
  'app_access': true,
});

// Mettre à jour
await client.policies.updateOne('policy-id', {'name': 'Read Only Users'});

// Supprimer
await client.policies.deleteOne('policy-id');
```

---

## 📝 Activity (ActivityService)

Accès : `client.activity`

```dart
// Lire les activités
DirectusResponse<dynamic> activities = await client.activity.readMany(
  query: QueryParameters(
    filter: Filter.field('action').equals('create'),
    sort: ['-timestamp'],
    limit: 50,
  ),
);

// Lire une activité
Map<String, dynamic> activity = await client.activity.readOne('activity-id');

// Créer un commentaire d'activité
Map<String, dynamic> comment = await client.activity.createComment({
  'collection': 'articles',
  'item': 'item-id',
  'comment': 'Great article!',
});
```

---

## 💬 Comments (CommentsService)

Accès : `client.comments`

```dart
// Lire les commentaires
DirectusResponse<dynamic> comments = await client.comments.readMany();

// Créer un commentaire
Map<String, dynamic> comment = await client.comments.createOne({
  'collection': 'articles',
  'item': 'article-id',
  'comment': 'Nice work!',
});

// Mettre à jour
await client.comments.updateOne('comment-id', {'comment': 'Updated text'});

// Supprimer
await client.comments.deleteOne('comment-id');
```

---

## 🗂️ Folders (FoldersService)

Accès : `client.folders`

```dart
// Lire les dossiers
DirectusResponse<dynamic> folders = await client.folders.readMany();

// Créer un dossier
Map<String, dynamic> folder = await client.folders.createOne({
  'name': 'Documents',
  'parent': 'parent-folder-id', // Optionnel
});

// Mettre à jour
await client.folders.updateOne('folder-id', {'name': 'Important Documents'});

// Supprimer
await client.folders.deleteOne('folder-id');
```

---

## 🔔 Notifications (NotificationsService)

Accès : `client.notifications`

```dart
// Lire les notifications
DirectusResponse<dynamic> notifications = await client.notifications.readMany(
  query: QueryParameters(filter: Filter.field('recipient').equals('user-id')),
);

// Créer une notification
Map<String, dynamic> notif = await client.notifications.createOne({
  'recipient': 'user-id',
  'subject': 'New Message',
  'message': 'You have a new message',
});

// Supprimer
await client.notifications.deleteOne('notif-id');
```

---

## 🔄 Flows (FlowsService)

Accès : `client.flows`

```dart
// Lire les flows
DirectusResponse<dynamic> flows = await client.flows.readMany();

// Lire un flow
Map<String, dynamic> flow = await client.flows.readOne('flow-id');

// Créer un flow
Map<String, dynamic> newFlow = await client.flows.createOne({
  'name': 'Email Notification',
  'icon': 'email',
  'status': 'active',
  'trigger': 'event',
  'accountability': 'all',
});

// Mettre à jour
await client.flows.updateOne('flow-id', {'status': 'inactive'});

// Supprimer
await client.flows.deleteOne('flow-id');
```

---

## ⚙️ Operations (OperationsService)

Accès : `client.operations`

```dart
// Lire les opérations
DirectusResponse<dynamic> operations = await client.operations.readMany();

// Créer une opération
Map<String, dynamic> op = await client.operations.createOne({
  'name': 'Send Email',
  'key': 'send_email',
  'type': 'email',
  'position_x': 10,
  'position_y': 10,
  'options': {'to': 'admin@example.com'},
  'flow': 'flow-id',
});

// Mettre à jour
await client.operations.updateOne('op-id', {'options': {'to': 'new@example.com'}});

// Supprimer
await client.operations.deleteOne('op-id');
```

---

## 📊 Dashboards & Panels

### DashboardsService

Accès : `client.dashboards`

```dart
// Lire les dashboards
DirectusResponse<dynamic> dashboards = await client.dashboards.readMany();

// Créer un dashboard
Map<String, dynamic> dashboard = await client.dashboards.createOne({
  'name': 'Analytics',
  'icon': 'dashboard',
});

// Mettre à jour
await client.dashboards.updateOne('dashboard-id', {'name': 'Stats'});

// Supprimer
await client.dashboards.deleteOne('dashboard-id');
```

### PanelsService

Accès : `client.panels`

```dart
// Lire les panels
DirectusResponse<dynamic> panels = await client.panels.readMany();

// Créer un panel
Map<String, dynamic> panel = await client.panels.createOne({
  'dashboard': 'dashboard-id',
  'name': 'User Count',
  'type': 'metric',
  'width': 6,
  'height': 4,
  'options': {'collection': 'users'},
});
```

---

## 📈 Metrics (MetricsService)

Accès : `client.metrics`

```dart
// Obtenir une métrique
Map<String, dynamic> metric = await client.metrics.query({
  'collection': 'articles',
  'type': 'count',
  'field': 'id',
});
```

---

## 🔧 Utilities (UtilitiesService)

Accès : `client.utilities`

### Export/Import

```dart
// Exporter une collection
dynamic export = await client.utilities.export(
  'articles',
  format: 'json', // json, csv, xml
  query: QueryParameters(limit: 100),
);

// Importer des données
dynamic result = await client.utilities.import(
  'articles',
  data: exportedData,
);
```

### Hash & Random

```dart
// Générer un hash
String hash = await client.utilities.generate('my-password');

// Vérifier un hash
bool isValid = await client.utilities.verify('my-password', hash);

// Générer une chaîne aléatoire
String random = await client.utilities.string(length: 32);
```

### Cache

```dart
// Vider le cache
await client.utilities.clear();

// Vider le cache d'une collection
await client.utilities.clearCollection('articles');
```

### Réorganisation

```dart
// Réorganiser les items (champ sort)
await client.utilities.reorder('articles', 'item-id', 5);
```

---

## 🗄️ Schema (SchemaService)

Accès : `client.schema`

```dart
// Snapshot du schéma
Map<String, dynamic> snapshot = await client.schema.snapshot();

// Appliquer un schéma
await client.schema.apply(schemaSnapshot);

// Différence entre schémas
Map<String, dynamic> diff = await client.schema.diff(
  currentSchema,
  targetSchema,
);
```

---

## 🖥️ Server (ServerService)

Accès : `client.server`

```dart
// Informations serveur
Map<String, dynamic> info = await client.server.info();

// Ping
Map<String, dynamic> pong = await client.server.ping();

// Santé du serveur
Map<String, dynamic> health = await client.server.health();

// Spécifications OpenAPI
Map<String, dynamic> specs = await client.server.openApiSpecs();
```

---

## ⚙️ Settings (SettingsService)

Accès : `client.settings`

```dart
// Lire les paramètres
Map<String, dynamic> settings = await client.settings.getSettings();

// Mettre à jour
Map<String, dynamic> updated = await client.settings.updateSettings({
  'project_name': 'Mon Projet',
  'project_url': 'https://example.com',
});
```

---

## 🔄 Revisions (RevisionsService)

Accès : `client.revisions`

```dart
// Lire les révisions
DirectusResponse<dynamic> revisions = await client.revisions.readMany(
  query: QueryParameters(
    filter: Filter.field('collection').equals('articles'),
    sort: ['-id'],
  ),
);

// Lire une révision
Map<String, dynamic> revision = await client.revisions.readOne('revision-id');
```

---

## 🔗 Shares (SharesService)

Accès : `client.shares`

```dart
// Créer un partage
Map<String, dynamic> share = await client.shares.createOne({
  'collection': 'articles',
  'item': 'article-id',
  'password': 'optional-password',
  'date_start': DateTime.now().toIso8601String(),
  'date_end': DateTime.now().add(Duration(days: 7)).toIso8601String(),
});

// Lire les partages
DirectusResponse<dynamic> shares = await client.shares.readMany();

// Supprimer
await client.shares.deleteOne('share-id');
```

---

## 🌐 Translations (TranslationsService)

Accès : `client.translations`

```dart
// Lire les traductions
DirectusResponse<dynamic> translations = await client.translations.getTranslations();

// Traductions par langue
DirectusResponse<dynamic> frTranslations = 
  await client.translations.getLanguageTranslations('fr-FR');

// Traduction par clé
DirectusResponse<dynamic> translation = 
  await client.translations.getTranslationByKey('welcome_message', 'fr-FR');

// Langues disponibles
List<String> languages = await client.translations.getAvailableLanguages();

// Créer une traduction
Map<String, dynamic> trans = await client.translations.createTranslation({
  'key': 'welcome_message',
  'language': 'fr-FR',
  'value': 'Bienvenue',
});
```

---

## 🔄 Versions (VersionsService)

Accès : `client.versions`

```dart
// Créer une version (Content Version)
Map<String, dynamic> version = await client.versions.createOne({
  'key': 'v1.0',
  'name': 'Version 1.0',
  'collection': 'articles',
  'item': 'article-id',
});

// Lire les versions
DirectusResponse<dynamic> versions = await client.versions.readMany();

// Promouvoir une version
await client.versions.promote('version-id', {
  'mainHash': 'hash-value',
});

// Sauvegarder une version
await client.versions.save('version-id', {
  'hash': 'hash-value',
});
```

---

## 🌐 WebSocket (DirectusWebSocketClient)

### Connexion

```dart
final ws = DirectusWebSocketClient(
  url: 'wss://directus.example.com/websocket',
  authToken: 'your-access-token', // Optionnel
);

await ws.connect();
await ws.disconnect();
```

### Subscriptions

```dart
// Souscrire à une collection
StreamSubscription sub = ws.subscribe(
  collection: 'articles',
  query: QueryParameters(
    fields: ['id', 'title'],
    filter: Filter.field('status').equals('published'),
  ),
  onMessage: (message) {
    print('Event: ${message['event']}');
    print('Data: ${message['data']}');
  },
  onError: (error) => print('Error: $error'),
);

// Se désabonner
await ws.unsubscribe('articles');

// Authentifier après connexion
await ws.authenticate('access-token');

// Envoyer un ping
await ws.ping();
```

---

## 🎨 Modèles personnalisés (DirectusModel)

### Création

```dart
class Article extends DirectusModel {
  Article(super.data);
  Article.empty() : super.empty();

  @override
  String get itemName => 'articles';

  // Property wrappers
  late final title = stringValue('title');
  late final content = stringValue('content');
  late final status = stringValue('status');
  late final views = intValue('views');
  late final published = boolValue('published');
  late final publishedAt = dateTimeValue('published_at');
  late final tags = listValue<String>('tags');
  late final author = modelValue<DirectusUser>('author');
  late final comments = modelListValue<Comment>('comments');
}
```

### Utilisation

```dart
// Lire avec le modèle
final articles = await client.itemsOf<Article>().readManyActive();
for (var article in articles.data) {
  print(article.title); // Accès direct
  article.title.set('New title'); // Modification
  await article.save(client); // Sauvegarde
}

// Créer
final newArticle = Article.empty()
  ..title.set('Mon article')
  ..content.set('Contenu')
  ..status.set('draft');
await newArticle.save(client);

// Supprimer
await article.delete(client);
```

---

## 🔍 QueryParameters complet

```dart
QueryParameters({
  // Filtres
  filter: Filter.and([
    Filter.field('status').equals('published'),
    Filter.field('views').greaterThan(1000),
  ]),
  
  // Champs à retourner
  fields: ['id', 'title', 'author.*', 'tags.name'],
  
  // Tri
  sort: ['-date_created', 'title'],
  
  // Pagination
  limit: 20,
  offset: 0,
  page: 1,
  
  // Recherche full-text
  search: 'keyword',
  
  // Relations
  deep: Deep()
    .field('author', fields: ['name', 'email'])
    .field('comments', limit: 5),
  
  // Agrégations
  aggregate: Aggregate()
    .count('id')
    .avg('rating'),
  
  // Groupement
  groupBy: ['category', 'status'],
});
```

---

## 🚨 Gestion d'erreurs

### Types d'exceptions

```dart
try {
  await client.items('articles').readMany();
} on DirectusAuthException catch (e) {
  // 401 - Non authentifié
  print('Auth error: ${e.message}');
  
  // Utiliser les helpers (recommandé)
  if (e.isOtpRequired) {
    print('OTP requis');
  }
  if (e.isInvalidCredentials) {
    print('Credentials invalides');
  }
  if (e.isInvalidToken) {
    print('Token invalide/expiré');
  }
  if (e.isUserSuspended) {
    print('Utilisateur suspendu');
  }
  
  // Ou vérifier avec DirectusErrorCode
  if (e.hasErrorCode(DirectusErrorCode.invalidOtp)) {
    print('Code OTP invalide');
  }
  
} on DirectusPermissionException catch (e) {
  // 403 - Permission refusée
  print('Permission error: ${e.message}');
} on DirectusNotFoundException catch (e) {
  // 404 - Non trouvé
  print('Not found: ${e.message}');
} on DirectusValidationException catch (e) {
  // 400 - Validation échouée
  print('Validation error: ${e.message}');
} on DirectusServerException catch (e) {
  // 5xx - Erreur serveur
  print('Server error: ${e.message}');
} on DirectusRateLimitException catch (e) {
  // 429 - Rate limit
  print('Rate limit: ${e.message}');
} on DirectusNetworkException catch (e) {
  // Erreur réseau/timeout
  print('Network error: ${e.message}');
} on DirectusException catch (e) {
  // Erreur générique
  print('Error: ${e.message} (${e.statusCode})');
  print('Code: ${e.errorCode}');
  print('Extensions: ${e.extensions}');
}
```

### DirectusErrorCode disponibles

```dart
// Authentification
DirectusErrorCode.invalidCredentials  // Credentials invalides
DirectusErrorCode.invalidToken        // Token invalide
DirectusErrorCode.tokenExpired        // Token expiré
DirectusErrorCode.invalidOtp          // OTP invalide (2FA)
DirectusErrorCode.userSuspended       // Utilisateur suspendu

// Validation
DirectusErrorCode.invalidPayload      // Payload invalide
DirectusErrorCode.invalidQuery        // Query invalide
DirectusErrorCode.containsNullValues  // Valeurs NULL
DirectusErrorCode.notNullViolation    // Violation NOT NULL
DirectusErrorCode.valueOutOfRange     // Valeur hors limites
DirectusErrorCode.valueTooLong        // Valeur trop longue

// Permissions
DirectusErrorCode.forbidden           // Accès interdit

// Ressources
DirectusErrorCode.routeNotFound       // Route non trouvée

// Serveur
DirectusErrorCode.internal            // Erreur serveur interne
DirectusErrorCode.serviceUnavailable  // Service indisponible

// Rate limiting
DirectusErrorCode.requestsExceeded    // Trop de requêtes
DirectusErrorCode.limitExceeded       // Limite dépassée

// Base de données
DirectusErrorCode.invalidForeignKey   // Clé étrangère invalide
DirectusErrorCode.recordNotUnique     // Enregistrement non unique

// Fichiers
DirectusErrorCode.contentTooLarge     // Contenu trop large
DirectusErrorCode.unsupportedMediaType // Type média non supporté
```

---

## 💡 Exemples rapides

### Authentification et récupération de données

```dart
final client = DirectusClient(DirectusConfig(
  baseUrl: 'https://directus.example.com',
));

await client.auth.login(
  email: 'user@example.com',
  password: 'password',
);

final articles = await client.items('articles').readMany(
  query: QueryParameters(
    fields: ['id', 'title', 'author.name'],
    filter: Filter.field('status').equals('published'),
    limit: 10,
  ),
);

for (var article in articles.data) {
  print('${article['title']} by ${article['author']['name']}');
}
```

### CRUD complet

```dart
// Create
final newItem = await client.items('articles').createOne({
  'title': 'New Article',
  'status': 'draft',
});

// Read
final item = await client.items('articles').readOne(newItem['id']);

// Update
await client.items('articles').updateOne(
  newItem['id'],
  {'status': 'published'},
);

// Delete
await client.items('articles').deleteOne(newItem['id']);
```

### Requête complexe avec relations et filtres

```dart
final results = await client.items('articles').readMany(
  query: QueryParameters(
    fields: ['*', 'author.*', 'tags.*.name'],
    filter: Filter.and([
      Filter.field('status').equals('published'),
      Filter.field('views').greaterThan(1000),
      Filter.relation('author', Filter.field('verified').equals(true)),
    ]),
    deep: Deep()
      .field('author', fields: ['id', 'name', 'avatar'])
      .field('comments', 
        fields: ['id', 'text'],
        filter: Filter.field('approved').equals(true),
        limit: 5,
      ),
    sort: ['-views', 'title'],
    limit: 20,
  ),
);
```

---

## 📚 Resources

- Documentation complète : `/docs/`
- Exemples : `/example/`
- API Reference : `/doc/api/`
- Directus API Docs : https://docs.directus.io/reference/

---

**Version** : 1.0.0  
**Date** : 30 octobre 2025
