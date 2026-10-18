# Couverture de l'API Directus

Correspondance entre chaque route REST de Directus et la méthode de la librairie.

**Référence** : routeur de Directus `main` (série 12.x, version 12.5.0 d'octobre 2026) et [documentation API](https://directus.com/docs/api).

> Le dossier `openapi/` du dépôt correspond à la spécification Directus **11.1.0** et ne reflète pas les routes ajoutées ou modifiées depuis. Les tableaux ci-dessous font foi.

Légende des notes : CRUD = `readMany`/`readOne`/`createOne`/`createMany`/`updateOne`/`updateMany`/`deleteOne`/`deleteMany` (voir [Services système](12-system-services.md)).

## Items (collections utilisateur)

| Route | Méthode |
|-------|---------|
| `GET /items/{collection}` | `items(c).readMany()` / `itemsOf<T>().readMany()` |
| `GET /items/{collection}/{id}` | `readOne(id)` |
| `POST /items/{collection}` | `createOne()` / `createMany()` |
| `PATCH /items/{collection}` | `updateMany()` / `updateSingleton()` |
| `PATCH /items/{collection}/{id}` | `updateOne()` |
| `DELETE /items/{collection}` | `deleteMany()` |
| `DELETE /items/{collection}/{id}` | `deleteOne()` |
| `GET /items/{singleton}` | `readSingleton()` |

Paramètres de requête (`QueryParameters`) : `fields`, `filter`, `search`, `sort`, `limit`, `offset`, `page`, `aggregate`, `groupBy`, `deep`, `alias`, `meta`, `version`, `versionRaw`, `backlink`.

## Authentification — `client.auth`

| Route | Méthode |
|-------|---------|
| `GET /auth` | `listOAuthProviders()` |
| `POST /auth/login` | `login()` |
| `POST /auth/login/{provider}` | `loginWithProvider()` (LDAP...) |
| `GET /auth/login/{provider}` | `getOAuthUrl()` (URL à ouvrir) |
| `POST /auth/refresh` | `refresh()`, `restoreSession()`, refresh automatique |
| `POST /auth/logout` | `logout()` |
| `POST /auth/password/request` | `requestPasswordReset()` |
| `POST /auth/password/reset` | `resetPassword()` |

## Accès et utilisateurs

| Route | Méthode |
|-------|---------|
| `/access` (CRUD) | `access` CRUD, `assignToRole()`, `assignToUser()` |
| `GET/POST/PATCH/DELETE /users[/{id}]` | `users.getUsers/getUser/createUser(s)/updateUser(s)/deleteUser(s)` |
| `GET /users/me` · `PATCH /users/me` | `users.me()` · `users.updateMe()` |
| `PATCH /users/me/track/page` | `users.updateLastPage()` |
| `POST /users/invite` · `/invite/accept` | `users.inviteUsers()` · `users.acceptInvite()` |
| `POST /users/register` | `users.register()` |
| `GET /users/register/verify-email?token=` | `users.verifyEmail()` |
| `POST /users/me/tfa/generate` · `/enable` · `/disable` | `generateTwoFactorSecret()` · `enableTwoFactor()` · `disableTwoFactor()` |
| `POST /users/{id}/tfa/disable` | `users.disableTwoFactorForUser()` (admin) |
| `/roles` (CRUD) | `roles.getRoles/getRole/createRole(s)/updateRole(s)/deleteRole(s)` |
| `GET /roles/me` | `roles.getMyRoles()` |
| `/policies` (CRUD) | `policies.getPolicies/getPolicy/createPolic(y/ies)/updatePolic(y/ies)/deletePolic(y/ies)` |
| `GET /policies/me/globals` | `policies.getMyGlobals()` |
| `/permissions` (CRUD) | `permissions.getPermissions/createPermission(s)/updatePermission(s)/deletePermission(s)` |
| `GET /permissions/me` | `permissions.getMyPermissions()` |
| `GET /permissions/me/{collection}/{id?}` | `permissions.getItemPermissions()` |

## Contenu et collaboration

| Route | Méthode |
|-------|---------|
| `GET /activity[/{id}]` | `activity.readMany/readOne`, `getActivities/getActivity` |
| `GET /revisions[/{id}]` | `revisions.readMany/readOne`, `getRevisions/getRevision` |
| `/comments` (CRUD) | `comments` CRUD + `getComments/createComment...` |
| `/notifications` (CRUD) | `notifications` CRUD + helpers |
| `/presets` (CRUD) | `presets` CRUD + helpers |
| `/translations` (CRUD) | `translations` CRUD + helpers |
| `/shares` (CRUD) | `shares` CRUD + helpers |
| `POST /shares/auth` | `shares.authenticate()` |
| `POST /shares/invite` | `shares.invite()` |
| `GET /shares/info/{id}` | `shares.info()` |
| `/versions` (CRUD) | `versions` CRUD + helpers |
| `GET /versions/{id}/compare` | `versions.compare()` |
| `POST /versions/{id}/save` | `versions.save()` |
| `POST /versions/{id}/promote` | `versions.promote()` |

## Fichiers et assets

| Route | Méthode |
|-------|---------|
| `/files` (CRUD) | `files` CRUD + `getFiles/getFile/updateFile/deleteFile` |
| `POST /files` (multipart) | `files.upload()`, `uploadFile()`, `uploadFileFromBytes()` |
| `PATCH /files/{id}` (multipart) | `files.replace()` |
| `POST /files/import` | `files.importFromUrl()`, `importFile()` |
| `/folders` (CRUD) | `folders` CRUD + helpers |
| `GET /assets/{id}` | `assets.getAssetUrl()` (URL), `assets.download()` (octets) |
| `GET /assets/folder/{id}` | `assets.downloadFolderZip()` |
| `POST /assets/files` | `assets.downloadFilesZip()` |

## Insights et automatisation

| Route | Méthode |
|-------|---------|
| `/dashboards` (CRUD) | `dashboards` CRUD + helpers |
| `/panels` (CRUD) | `panels` CRUD + helpers |
| `/flows` (CRUD) | `flows` CRUD + helpers |
| `GET /flows/trigger/{id}` | `flows.triggerFlowGet()` |
| `POST /flows/trigger/{id}` | `flows.triggerFlow()` |
| `/operations` (CRUD) | `operations` CRUD + helpers |

## Schéma

| Route | Méthode |
|-------|---------|
| `GET/POST /collections` · `GET/PATCH/DELETE /collections/{c}` | `collections.getCollections/createCollection/getCollection/updateCollection/deleteCollection` |
| `PATCH /collections` | `collections.updateCollections()` |
| `GET /fields` · `GET /fields/{c}` · `GET /fields/{c}/{f}` | `fields.getAllFields/getFieldsInCollection/getField` |
| `POST /fields/{c}` · `PATCH/DELETE /fields/{c}/{f}` | `fields.createField/updateField/deleteField` |
| `PATCH /fields/{c}` | `fields.updateFields()` |
| `GET /relations` · `GET /relations/{c}` · `GET /relations/{c}/{f}` | `relations.readAll/readByCollection/readOne` |
| `POST /relations` · `PATCH/DELETE /relations/{c}/{f}` | `relations.create/update/delete` |
| `GET /schema/snapshot` | `schema.snapshot()` |
| `POST /schema/diff` | `schema.diff()` |
| `POST /schema/apply` | `schema.apply()` |

## Projet et serveur

| Route | Méthode |
|-------|---------|
| `GET /settings` · `PATCH /settings` | `settings.read()` · `settings.update()` |
| `POST /settings/owner` | `settings.setOwner()` |
| `GET /server/ping` | `server.ping()` (public) |
| `GET /server/health` | `server.health()` (authentifié depuis 12.0) |
| `GET /server/info` | `server.info()` |
| `GET /server/specs/oas` | `server.specs()` |
| `GET /server/specs/graphql/{scope}` | `server.graphqlSdl()` |
| `POST /server/setup` | `server.setup()` |
| `GET /metrics` | `metrics.getMetrics()` (texte Prometheus) |
| `/extensions` · `PATCH/DELETE /extensions/{id}` | `extensions.getExtensions/updateExtension/deleteExtension` |
| `/extensions/registry/*` | `extensions.searchRegistry/getRegistryExtension/getRegistryAccount/install/reinstall/uninstall` |
| `/license/*` | `license.read/activate/update/remove/preview/portal/addons/setAddonQuantity/removeAddon/pendingResolution/resolve` |
| `/deployments/*` | `deployments.readMany/create/read/update/delete/projects/project/updateProjects/dashboard/deploy/runs/runStats/run/cancelRun` |

## Utilitaires — `client.utilities`

| Route | Méthode |
|-------|---------|
| `GET /utils/random/string` | `random.string()` |
| `POST /utils/sort/{collection}` | `sort.reorder()` |
| `POST /utils/revert/{revision}` | `revert()` |
| `POST /utils/import/{collection}` (multipart) | `import()` |
| `POST /utils/import` | `importBatch()` |
| `POST /utils/export/{collection}` | `export()` |
| `POST /utils/cache/clear` | `cache.clear(system:)` |
| `POST /utils/translations/generate` | `generateTranslations()` |
| `POST /utils/resolve-redirect` | `resolveRedirect()` |

## WebSocket — `client.websocket`

| Message | Méthode |
|---------|---------|
| `auth` | automatique à `connect()` |
| `subscribe` / `unsubscribe` | `subscribe()` / `unsubscribe()` |
| `items` | `items()` |
| `ping` / `pong` | réponse automatique, `ping()` |

## Volontairement non couverts

| Route | Raison |
|-------|--------|
| `SEARCH /<collection>` | Variante de `GET` avec requête dans le body ; les mêmes requêtes passent par `GET`. |
| `/graphql`, `/graphql/system` | Librairie REST ; utiliser un client GraphQL dédié. |
| `/files/tus` | Protocole d'upload résumable TUS : utiliser un client TUS. |
| `/mcp`, `/mcp-oauth/clients` | Serveur MCP destiné aux agents IA, pas aux applications. |
| `/ai`, `/ai/files` | Chat IA interne au Data Studio. |
| `/extensions/sources/{chunk}` | Bundle JavaScript de l'application d'administration. |
| `/deployments/webhooks` | Webhooks entrants des hébergeurs. |
| `/utils/hash/*` | Supprimés en 12.1 (`utilities.hash` est déprécié). |

## Changements Directus à connaître (11.1 → 12.5)

- **11.1.2** : commentaires dans `directus_comments` (`/comments`), identifiants UUID.
- **11.x** : permissions portées par les policies ; attribution via `/access`.
- **12.0** : `/server/health` exige une authentification ; `?version=main` devient `?version=published`.
- **12.1** : suppression de `/utils/hash/*` ; `CORS_ORIGIN` contrôlé pour les WebSockets.
- **12.2** : drapeaux de requête sans valeur (`?force`) valent `true` ; import limité à `IMPORT_MAX_FILE_SIZE` (50 Mo par défaut, erreur 413).
- **12.4** : collection inactive → `COLLECTION_INACTIVE` (403) ; `directus_folders.type` (`files` / `flows`) ; update/delete par requête soumis aux permissions de lecture.
- **12.5** : `GET /license` renvoie `invalid_reason` ; `storage` d'un fichier doit correspondre à `STORAGE_LOCATIONS` ; `LICENSE_INVALID`.
