# Services système orientés objet

Les collections système Directus (`directus_comments`, `directus_flows`, `directus_files`...) sont exposées par des services dédiés qui manipulent des **modèles typés** (classes héritant de `DirectusModel`) plutôt que des `Map`.

## Principe

Directus refuse l'accès aux collections système via `/items/directus_*` (403). Chaque collection système a son propre endpoint : `directus_comments` → `/comments`, `directus_users` → `/users`, etc.

La fonction `directusCollectionPath(collection)` fait cette correspondance. Elle est utilisée par `ItemsService` et `ItemActiveService`. Ainsi :

```dart
client.items('articles');            // → /items/articles
client.items('directus_comments');   // → /comments
client.itemsOf<DirectusComment>();   // → /comments (via itemName)
```

## Classes de base

| Classe | Méthodes | Usage |
|--------|----------|-------|
| `DirectusReadOnlySystemService<T>` | `readMany`, `readOne` | Collections en lecture seule |
| `DirectusSystemService<T>` | + `createOne`, `createMany`, `updateOne`, `updateMany`, `deleteOne`, `deleteMany` | Collections en lecture/écriture |

- `updateOne(model)` n'envoie que les champs modifiés (`toJsonDirty()`).
- `deleteOne(model)` utilise `model.id`.
- `active` expose l'`ItemActiveService<T>` sous-jacent (ex. `updateManyIndividual`).
- La factory du modèle est enregistrée automatiquement **si aucune n'existe** : une sous-classe personnalisée enregistrée avant la création du client est respectée.

## Services et modèles

| Service (`client.`) | Modèle | Base | Endpoint |
|---------------------|--------|------|----------|
| `activity` | `DirectusActivity` | lecture seule | `/activity` |
| `revisions` | `DirectusRevision` | lecture seule | `/revisions` |
| `comments` | `DirectusComment` | lecture/écriture | `/comments` |
| `dashboards` | `DirectusDashboard` | lecture/écriture | `/dashboards` |
| `panels` | `DirectusPanel` | lecture/écriture | `/panels` |
| `flows` | `DirectusFlow` | lecture/écriture | `/flows` |
| `operations` | `DirectusOperation` | lecture/écriture | `/operations` |
| `folders` | `DirectusFolder` | lecture/écriture | `/folders` |
| `files` | `DirectusFile` | lecture/écriture | `/files` |
| `notifications` | `DirectusNotification` | lecture/écriture | `/notifications` |
| `presets` | `DirectusPreset` | lecture/écriture | `/presets` |
| `shares` | `DirectusShare` | lecture/écriture | `/shares` |
| `translations` | `DirectusTranslation` | lecture/écriture | `/translations` |
| `versions` | `DirectusVersion` | lecture/écriture | `/versions` |
| `access` | `DirectusAccess` | lecture/écriture | `/access` |

Services typés spécifiques (API propre, sans classe de base) :

| Service | Modèle | Méthodes typées |
|---------|--------|-----------------|
| `users` | `DirectusUser` | `getUsers<T>`, `getUser<T>`, `me<T>`, `createUser`, ... |
| `roles` | `DirectusRole` | `getRoles<T>`, `getRole<T>`, `getMyRoles<T>`, ... |
| `policies` | `DirectusPolicy` | `getPolicies<T>`, `getPolicy<T>`, `getMyGlobals()`, ... |
| `permissions` | `DirectusPermission` | `getPermissions<T>`, `createPermission<T>`, ... |
| `relations` | `DirectusRelation` | `readAll`, `readByCollection`, `readOne`, `create`, `update`, `delete` |
| `settings` | `DirectusSettings` | `read`, `update`, `setOwner` |

Les anciennes méthodes renvoyant des `Map` (`getComments`, `createFlow`, `getFolders`...) restent disponibles. Elles passent maintenant par le bon endpoint.

## Exemples

### Commentaires

```dart
final comment = DirectusComment.empty()
  ..collection.set('articles')
  ..item.set('15')
  ..comment.set('Relu et validé');

final created = await client.comments.createOne(comment);

created!.comment.set('Relu, validé et publié');
await client.comments.updateOne(created);

final page = await client.comments.readMany(
  query: QueryParameters(
    filter: Filter.field('item').equals('15'),
    sort: ['-date_created'],
  ),
);
for (final c in page.data) {
  print(c.comment.value);
}

await client.comments.deleteOne(created);
```

### Attribuer une policy

```dart
await client.access.assignToUser(userId: user.id!, policyId: policy.id!);
await client.access.assignToRole(roleId: role.id!, policyId: policy.id!);
```

### Versions de contenu

```dart
final version = await client.versions.createOne(
  DirectusVersion.empty()
    ..key.set('draft')
    ..name.set('Brouillon')
    ..collection.set('articles')
    ..item.set('15'),
);

await client.versions.save(version!.id!, {'title': 'Titre en cours'});

final diff = await client.versions.compare(version.id!);
if (diff['outdated'] == true) {
  // l'item principal a changé depuis la création de la version
}
await client.versions.promote(version.id!, mainHash: diff['mainHash']);

// Lire un item dans une version
final draft = await client.items('articles').readOne(
  '15',
  query: QueryParameters(version: 'draft'),
);
```

### Relations

```dart
final relation = await client.relations.readOne('articles', 'author');
print(relation.relatedCollection.value); // directus_users
print(relation.relationType);            // Many-to-One
print(relation.oneField.value);          // alias O2M côté users (meta.one_field)
```

### Paramètres

```dart
final settings = await client.settings.read();
settings.projectColor.set('#6644FF');
await client.settings.update(settings);
```

## Personnaliser un modèle système

```dart
class MyUser extends DirectusUser {
  MyUser(super.data);
  late final department = stringValue('department');
}

// À enregistrer AVANT de créer le DirectusClient
DirectusModel.registerFactory<MyUser>((data) => MyUser(data));

final users = await client.users.getUsers<MyUser>();
```
