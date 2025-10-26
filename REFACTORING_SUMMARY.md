# Résumé de la Refonte: DirectusActiveModel → DirectusModel

## 🎯 Objectif

Simplifier l'API en unifiant les deux approches de modélisation sous un seul nom : `DirectusModel`, qui utilise désormais le pattern Active Record (stockage JSON interne).

## ✅ Actions effectuées

### 1. Suppression de l'ancien système

**Fichiers supprimés :**
- `lib/src/models/directus_builder.dart` - Ancien builder pattern
- `lib/src/models/directus_serializable.dart` - Ancien registry/serialization
- `lib/src/models/directus_annotations.dart` - Annotations non utilisées
- Ancien `lib/src/models/directus_model.dart` - Classe abstraite traditionnelle

**Exemples/Tests supprimés :**
- `example/custom_model.dart`
- `example/directus_model_example.dart` (ancien)
- `example/simple_model_example.dart`
- `example/advanced_builders_example.dart`
- `test/models/directus_model_test.dart` (ancien)
- `test/models/directus_builder_test.dart`

### 2. Renommage du nouveau système

**Renommages effectués :**
- `DirectusActiveModel` → `DirectusModel` (classe principale)
- `DynamicActiveModel` → `DynamicModel` (implémentation concrète)
- `lib/src/models/directus_active_model.dart` → `lib/src/models/directus_model.dart`
- `example/active_model_example.dart` → `example/directus_model_example.dart`

**Dans les exemples :**
- `ActiveProduct` → `Product`
- `ActiveCategory` → `Category`
- `ActiveUser` → `User`
- `ActiveOrder` → `Order`

### 3. Mise à jour des imports

**Fichiers mis à jour :**
- `lib/fcs_directus.dart` - Export simplifié (seulement `directus_model.dart`)
- `lib/src/services/items_service.dart` - Import du nouveau DirectusModel
- `example/directus_model_example.dart` - Import corrigé
- `example/README.md` - Documentation mise à jour

## 📦 Nouvelle API unifiée

### Classe principale : DirectusModel

```dart
abstract class DirectusModel {
  // Stockage JSON interne
  final Map<String, dynamic> _data;
  
  // Constructeurs
  DirectusModel(Map<String, dynamic> data);
  DirectusModel.empty();
  
  // Champs standards Directus
  String? get id;
  DateTime? get dateCreated;
  DateTime? get dateUpdated;
  String? get userCreated;
  String? get userUpdated;
  
  // Getters typés
  String getString(String key, {String defaultValue});
  int getInt(String key, {int defaultValue});
  double getDouble(String key, {double defaultValue});
  bool getBool(String key, {bool defaultValue});
  DateTime? getDateTime(String key);
  List<T> getList<T>(String key);
  Map<String, dynamic>? getObject(String key);
  T getDirectusModel<T extends DirectusModel>(String key);
  List<T> getDirectusModelList<T extends DirectusModel>(String key);
  
  // Setters typés
  void setString(String key, String value);
  void setInt(String key, int value);
  void setDouble(String key, double value);
  void setBool(String key, bool value);
  void setDateTime(String key, DateTime value);
  void setList<T>(String key, List<T> value);
  void setObject(String key, Map<String, dynamic> value);
  void setDirectusModel(String key, DirectusModel value);
  void setDirectusModelList(String key, List<DirectusModel> value);
  
  // Helpers
  bool has(String key);
  void remove(String key);
  Map<String, dynamic> toJson();
  Map<String, dynamic> toMap();
  
  // Registry pour instanciation
  static void registerFactory<T extends DirectusModel>(...);
  static void unregisterFactory<T extends DirectusModel>();
  static void clearFactories();
}
```

### Exemple d'utilisation

```dart
import 'package:fcs_directus/fcs_directus.dart';

// Définir un modèle
class Product extends DirectusModel {
  Product(super.data);
  
  String get name => getString('name');
  double get price => getDouble('price');
  int get stock => getInt('stock');
  
  set name(String value) => setString('name', value);
  set price(double value) => setDouble('price', value);
  set stock(int value) => setInt('stock', value);
}

// Utilisation
void main() {
  // Enregistrer la factory
  DirectusModel.registerFactory<Product>((data) => Product(data));
  
  // Créer depuis JSON
  final product = Product({
    'id': '1',
    'name': 'Laptop',
    'price': 999.99,
    'stock': 10,
  });
  
  // Modifier
  product.price = 1299.99;
  product.stock = 15;
  
  // Sérialiser
  print(product.toJson()); // JSON complet
  print(product.toMap());  // Sans champs système
}
```

## 🎉 Avantages du nouveau système

1. **API unifiée** - Un seul nom `DirectusModel` au lieu de deux approches différentes
2. **Simplicité** - Pas besoin de `fromJson()`/`toMap()` manuels
3. **Type-safe** - Getters/setters typés avec conversions automatiques
4. **Active Record** - Modification directe des données
5. **Relations** - Support des objets et listes de DirectusModel nested
6. **Flexibilité** - Registry pour instanciation dynamique

## ✅ Tests

- **18 tests unitaires** passent avec succès
- **Exemple complet** fonctionne correctement
- **Analyse statique** : seulement des warnings mineurs (avoid_print)

## 📝 Fichiers restants

### Code source (lib/)
- `lib/src/models/directus_model.dart` - Classe principale (Active Record)
- `lib/src/services/items_service.dart` - Service avec support DirectusModel
- `lib/fcs_directus.dart` - Export simplifié

### Exemples (example/)
- `example/basic_usage.dart` - CRUD basique
- `example/directus_model_example.dart` - Active Record pattern complet
- `example/websocket_example.dart` - WebSockets

### Tests (test/)
- `test/fcs_directus_test.dart` - Tests principaux (18 tests)

## 🚀 Migration pour les utilisateurs

Pour les utilisateurs existants utilisant l'ancien `DirectusModel`:

```dart
// Avant (ancien système)
class Product extends DirectusModel {
  final String name;
  final double price;
  
  Product({String? id, required this.name, required this.price})
    : super(id: id);
  
  @override
  Map<String, dynamic> toMap() => {'name': name, 'price': price};
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: DirectusModel.parseId(json['id']),
      name: json['name'],
      price: json['price'],
    );
  }
}

// Après (nouveau système)
class Product extends DirectusModel {
  Product(super.data);
  
  String get name => getString('name');
  double get price => getDouble('price');
  
  set name(String value) => setString('name', value);
  set price(double value) => setDouble('price', value);
}
```

**Avantages :**
- ❌ Plus de `fromJson()` manuel (- 10 lignes)
- ❌ Plus de `toMap()` manuel (- 5 lignes)
- ✅ Getters/setters en 1 ligne chacun
- ✅ Modification directe des données
- ✅ **50% de code en moins !**

---

**Date de la refonte :** 26 octobre 2025  
**Version :** v0.3.0 (prévue)
