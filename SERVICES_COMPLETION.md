# Ajout des nouveaux services Directus

## Résumé

Tous les services demandés ont été implémentés avec succès dans la librairie fcs_directus.

## Services ajoutés

### 1. ✅ NotificationsService (`notifications_service.dart`)
- **Modèle**: `DirectusNotification`
- **Collection**: `directus_notifications`
- **Méthodes CRUD**: getNotifications, getNotification, createNotification, updateNotification, deleteNotification, deleteNotifications
- **Méthodes helper**:
  - `getInboxNotifications()` - Récupère les notifications non lues
  - `getArchivedNotifications()` - Récupère les notifications archivées
  - `getUserNotifications(userId)` - Récupère les notifications d'un utilisateur
  - `archiveNotification(id)` - Archive une notification

### 2. ✅ PermissionsService (`permissions_service.dart`)
- **Modèle**: `DirectusPermission`
- **Collection**: `directus_permissions`
- **Méthodes CRUD**: getPermissions, getPermission, createPermission, updatePermission, deletePermission, deletePermissions
- **Méthodes helper**:
  - `getPermissionsByPolicy(policyId)` - Permissions d'une politique
  - `getPermissionsByCollection(collection)` - Permissions d'une collection
  - `getMyPermissions()` - Permissions de l'utilisateur courant
  - `getItemPermissions(collection, itemId)` - Permissions d'un item spécifique

### 3. ✅ PresetsService (`presets_service.dart`)
- **Modèle**: `DirectusPreset`
- **Collection**: `directus_presets`
- **Méthodes CRUD**: getPresets, getPreset, createPreset, updatePreset, deletePreset, deletePresets
- **Méthodes helper**:
  - `getBookmarks()` - Récupère les signets
  - `getUserPresets(userId)` - Préférences d'un utilisateur
  - `getRolePresets(roleId)` - Préférences d'un rôle
  - `getGlobalPresets()` - Préférences globales

### 4. ✅ RelationsService (`relations_service.dart`)
- **Modèle**: `DirectusRelation`
- **Endpoints REST**: `/relations`, `/relations/:id`, `/relations/:collection`
- **Méthodes**:
  - `getRelations()` - Toutes les relations
  - `getRelation(id)` - Une relation spécifique
  - `getRelationsByCollection(collection)` - Relations d'une collection
  - `createRelation(data)` - Créer une relation
  - `updateRelation(id, data)` - Mettre à jour une relation
  - `deleteRelation(id)` - Supprimer une relation

### 5. ✅ RevisionsService (`revisions_service.dart`)
- **Modèle**: `DirectusRevision` (existant)
- **Collection**: `directus_revisions`
- **Méthodes CRUD**: getRevisions, getRevision
- **Méthodes helper**:
  - `getItemRevisions(collection, itemId)` - Révisions d'un item
  - `getCollectionRevisions(collection)` - Révisions d'une collection

### 6. ✅ OperationsService (`operations_service.dart`)
- **Modèle**: `DirectusOperation` (existant)
- **Collection**: `directus_operations`
- **Méthodes CRUD**: getOperations, getOperation, createOperation, updateOperation, deleteOperation, deleteOperations
- **Méthodes helper**:
  - `getFlowOperations(flowId)` - Opérations d'un flow
  - `getOperationsByType(type)` - Opérations par type
  - `getResolveOperations(flowId)` - Opérations résolues d'un flow

### 7. ✅ PanelsService (`panels_service.dart`)
- **Modèle**: `DirectusPanel` (existant)
- **Collection**: `directus_panels`
- **Méthodes CRUD**: getPanels, getPanel, createPanel, updatePanel, deletePanel, deletePanels
- **Méthodes helper**:
  - `getDashboardPanels(dashboardId)` - Panneaux d'un dashboard
  - `getPanelsByType(type)` - Panneaux par type
  - `getFullWidthPanels(dashboardId)` - Panneaux pleine largeur

### 8. ✅ MetricsService (`metrics_service.dart`)
- **Endpoint REST**: `/metrics`
- **Méthode**:
  - `getMetrics()` - Récupère les métriques du serveur (version, uptime, statistiques)

### 9. ✅ RolesService (déjà existant)
- **Modèle**: `DirectusRole`
- **Collection**: `directus_roles`
- Service déjà implémenté dans le projet

### 10. ✅ PoliciesService (déjà existant)
- **Modèle**: `DirectusPolicy`
- **Collection**: `directus_policies`
- Service déjà implémenté dans le projet

## Nouveaux modèles créés

1. **DirectusNotification** (`directus_notification.dart`)
   - Propriétés: id, timestamp, status, recipient, sender, subject, message, collection, item
   - Helpers: isInInbox, isArchived, recipientUser, senderUser, archive(), formattedTimestamp

2. **DirectusPermission** (`directus_permission.dart`)
   - Propriétés: id, collection, action, permissions, validation, presets, fields, policy
   - Helpers: isCreate, isRead, isUpdate, isDelete, hasPermissions, allowsAllFields, policyObject

3. **DirectusPreset** (`directus_preset.dart`)
   - Propriétés: id, bookmark, user, role, collection, search, layout, layoutQuery, layoutOptions, filters
   - Helpers: isBookmark, isUserSpecific, isRoleSpecific, isGlobal, displayName

4. **DirectusRelation** (`directus_relation.dart`)
   - Propriétés: id, manyCollection, manyField, oneCollection, oneField, junctionField, sortField
   - Helpers: isManyToOne, isOneToMany, isManyToMany, relationType, summary

## Intégration dans DirectusClient

Tous les services sont maintenant disponibles via le `DirectusClient` :

```dart
final client = DirectusClient(config);

// Utilisation des nouveaux services
await client.notifications.getInboxNotifications();
await client.permissions.getMyPermissions();
await client.presets.getBookmarks();
await client.relations.getRelationsByCollection('articles');
await client.revisions.getItemRevisions('articles', '15');
await client.operations.getFlowOperations(flowId);
await client.panels.getDashboardPanels(dashboardId);
await client.metrics.getMetrics();
await client.roles.getRoles();
await client.policies.getPolicies();
```

## Exports mis à jour

Tous les nouveaux services et modèles ont été ajoutés au fichier `fcs_directus.dart` :

- Services: notifications, permissions, presets, relations, revisions, operations, panels, metrics
- Modèles: DirectusNotification, DirectusPermission, DirectusPreset, DirectusRelation

## Architecture

Tous les services suivent le même pattern :
1. Utilisation de `ItemsService` comme wrapper pour les opérations CRUD standard
2. Méthodes helper utilisant `Filter` pour les requêtes spécialisées
3. Support de `QueryParameters` pour les options avancées (fields, sort, limit, etc.)
4. Documentation complète avec exemples d'utilisation

## Compilation

✅ Aucune erreur de compilation
✅ Tous les imports sont corrects
✅ Tous les services sont intégrés dans DirectusClient
✅ Tous les exports sont à jour dans fcs_directus.dart

## Tests

Les tests peuvent être exécutés avec :
```bash
dart test
# ou
flutter test
```

## Prochaines étapes

Les services sont maintenant prêts à être utilisés. Vous pouvez :
1. Tester les services avec votre serveur Directus
2. Ajouter des tests unitaires pour les nouveaux services
3. Mettre à jour la documentation utilisateur si nécessaire
4. Créer des exemples d'utilisation dans le dossier `example/`
