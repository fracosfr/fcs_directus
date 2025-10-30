# Modification de DirectusItemEvent pour WebSocket

## Résumé
Ajout d'un enum `DirectusItemEvent` pour type-safety au lieu d'utiliser des String pour les événements CRUD.

## Enum créé
```dart
/// Événements CRUD sur les items Directus
enum DirectusItemEvent {
  /// Un nouvel item a été créé
  create,
  
  /// Un item existant a été modifié
  update,
  
  /// Un item a été supprimé
  delete;

  /// Convertit une string en DirectusItemEvent
  static DirectusItemEvent? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'create':
        return DirectusItemEvent.create;
      case 'update':
        return DirectusItemEvent.update;
      case 'delete':
        return DirectusItemEvent.delete;
      default:
        return null;
    }
  }

  /// Convertit l'enum en string pour l'API
  String toApiString() {
    return name;
  }
}
```

## Modifications à faire

### 1. Dans `DirectusWebSocketMessage`:
- Changer `final String? event` → `final DirectusItemEvent? event`
- Dans `fromJson`: `event: DirectusItemEvent.fromString(json['event'] as String?)`
- Dans `toJson`: `if (event != null) 'event': event!.toApiString()`

### 2. Dans la méthode `subscribe()`:
- Paramètre: `DirectusItemEvent? event` au lieu de `String? event`
- Dans l'envoi: `if (event != null) 'event': event.toApiString()`

### 3. Dans toutes les méthodes helper (18):
- subscribeToUsers, subscribeToFiles, etc.
- Changer le paramètre `String? event` → `DirectusItemEvent? event`

### 4. Dans les méthodes helper d'événements (3):
- subscribeToCreate: passer `event: DirectusItemEvent.create`
- subscribeToUpdate: passer `event: DirectusItemEvent.update`  
- subscribeToDelete: passer `event: DirectusItemEvent.delete`

### 5. Dans les tests et exemples:
- Remplacer `event: 'create'` → `event: DirectusItemEvent.create`
- Remplacer `event: 'update'` → `event: DirectusItemEvent.update`
- Remplacer `event: 'delete'` → `event: DirectusItemEvent.delete`

## Bénéfices
- ✅ Type-safety: impossible de passer une mauvaise valeur
- ✅ Auto-complétion dans l'IDE
- ✅ Documentation claire des valeurs possibles
- ✅ Conversion automatique string ↔ enum
