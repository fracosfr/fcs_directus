/// Modèle Directus avec stockage JSON interne (Active Record pattern).
///
/// Cette approche stocke les données JSON directement dans l'objet
/// et fournit des méthodes typées pour y accéder et les modifier.
///
/// Exemple d'utilisation:
/// ```dart
/// class Product extends DirectusModel {
///   Product(super.data);
///
///   @override
///   String get itemName => 'products';
///
///   String get name => getString('name');
///   set name(String value) => setString('name', value);
///
///   double get price => getDouble('price');
///   set price(double value) => setDouble('price', value);
/// }
///
/// // Utilisation
/// final product = Product({'name': 'Laptop', 'price': 999.99});
/// print(product.name);  // Laptop
/// product.price = 1299.99;
/// print(product.toJson());  // JSON mis à jour
/// ```
abstract class DirectusModel {
  /// Données JSON internes
  final Map<String, dynamic> _data;

  /// Nom de la collection Directus
  String get itemName;

  /// Crée un modèle depuis des données JSON
  DirectusModel(Map<String, dynamic> data) : _data = Map.from(data);

  /// Crée un modèle vide
  DirectusModel.empty() : _data = {};

  // === Champs standards Directus ===

  /// Identifiant unique
  String? get id => _data['id']?.toString();
  set id(String? value) =>
      value == null ? _data.remove('id') : _data['id'] = value;

  /// Date de création
  DateTime? get dateCreated => _parseDate(_data['date_created']);
  set dateCreated(DateTime? value) => value == null
      ? _data.remove('date_created')
      : _data['date_created'] = value.toIso8601String();

  /// Date de dernière modification
  DateTime? get dateUpdated => _parseDate(_data['date_updated']);
  set dateUpdated(DateTime? value) => value == null
      ? _data.remove('date_updated')
      : _data['date_updated'] = value.toIso8601String();

  /// Utilisateur créateur
  String? get userCreated => _data['user_created']?.toString();
  set userCreated(String? value) => value == null
      ? _data.remove('user_created')
      : _data['user_created'] = value;

  /// Utilisateur modificateur
  String? get userUpdated => _data['user_updated']?.toString();
  set userUpdated(String? value) => value == null
      ? _data.remove('user_updated')
      : _data['user_updated'] = value;

  // === Getters typés ===

  /// Récupère une valeur String
  String getString(String key, {String defaultValue = ''}) {
    final value = _data[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Récupère une valeur String nullable
  String? getStringOrNull(String key) {
    final value = _data[key];
    if (value == null) return null;
    return value.toString();
  }

  /// Récupère une valeur int
  int getInt(String key, {int defaultValue = 0}) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Récupère une valeur int nullable
  int? getIntOrNull(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Récupère une valeur double
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Récupère une valeur double nullable
  double? getDoubleOrNull(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Récupère une valeur bool
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  /// Récupère une valeur bool nullable
  bool? getBoolOrNull(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  /// Récupère une valeur DateTime
  DateTime? getDateTime(String key) {
    return _parseDate(_data[key]);
  }

  /// Récupère une liste
  List<T> getList<T>(String key) {
    final value = _data[key];
    if (value == null) return [];
    if (value is! List) return [];
    return List<T>.from(value);
  }

  /// Récupère un objet nested
  Map<String, dynamic>? getObject(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  /// Récupère un modèle DirectusModel nested
  ///
  /// Exemple:
  /// ```dart
  /// Category get category => getDirectusModel<Category>('category');
  /// ```
  T getDirectusModel<T extends DirectusModel>(String key) {
    final value = _data[key];
    if (value == null) {
      throw StateError('Field "$key" is null or does not exist');
    }

    Map<String, dynamic> data;
    if (value is Map<String, dynamic>) {
      data = value;
    } else if (value is Map) {
      data = Map<String, dynamic>.from(value);
    } else {
      throw StateError('Field "$key" is not a Map');
    }

    // Créer une instance du type T
    // Note: Cela nécessite que T ait un constructeur qui accepte Map<String, dynamic>
    return _createInstance<T>(data);
  }

  /// Récupère un modèle DirectusModel nested nullable
  T? getDirectusModelOrNull<T extends DirectusModel>(String key) {
    final value = _data[key];
    if (value == null) return null;

    Map<String, dynamic> data;
    if (value is Map<String, dynamic>) {
      data = value;
    } else if (value is Map) {
      data = Map<String, dynamic>.from(value);
    } else {
      return null;
    }

    return _createInstance<T>(data);
  }

  /// Récupère une liste de modèles DirectusModel
  ///
  /// Exemple:
  /// ```dart
  /// List<Product> get products => getDirectusModelList<Product>('products');
  /// ```
  List<T> getDirectusModelList<T extends DirectusModel>(String key) {
    final value = _data[key];
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .map((item) {
          if (item == null) return null;

          Map<String, dynamic> data;
          if (item is Map<String, dynamic>) {
            data = item;
          } else if (item is Map) {
            data = Map<String, dynamic>.from(item);
          } else {
            return null;
          }

          return _createInstance<T>(data);
        })
        .whereType<T>()
        .toList();
  }

  /// Récupère une liste de modèles DirectusModel (nullable)
  List<T>? getDirectusModelListOrNull<T extends DirectusModel>(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! List) return null;

    return value
        .map((item) {
          if (item == null) return null;

          Map<String, dynamic> data;
          if (item is Map<String, dynamic>) {
            data = item;
          } else if (item is Map) {
            data = Map<String, dynamic>.from(item);
          } else {
            return null;
          }

          return _createInstance<T>(data);
        })
        .whereType<T>()
        .toList();
  }

  /// Vérifie si une clé existe
  bool has(String key) => _data.containsKey(key);

  // === Setters typés ===

  /// Définit une valeur String
  void setString(String key, String value) {
    _data[key] = value;
  }

  /// Définit une valeur String nullable
  void setStringOrNull(String key, String? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  /// Définit une valeur int
  void setInt(String key, int value) {
    _data[key] = value;
  }

  /// Définit une valeur int nullable
  void setIntOrNull(String key, int? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  /// Définit une valeur double
  void setDouble(String key, double value) {
    _data[key] = value;
  }

  /// Définit une valeur double nullable
  void setDoubleOrNull(String key, double? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  /// Définit une valeur bool
  void setBool(String key, bool value) {
    _data[key] = value;
  }

  /// Définit une valeur bool nullable
  void setBoolOrNull(String key, bool? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  /// Définit une valeur DateTime
  void setDateTime(String key, DateTime value) {
    _data[key] = value.toIso8601String();
  }

  /// Définit une valeur DateTime nullable
  void setDateTimeOrNull(String key, DateTime? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.toIso8601String();
    }
  }

  /// Définit une liste
  void setList<T>(String key, List<T> value) {
    _data[key] = value;
  }

  /// Définit un objet nested
  void setObject(String key, Map<String, dynamic> value) {
    _data[key] = value;
  }

  /// Définit un modèle DirectusModel nested
  ///
  /// Exemple:
  /// ```dart
  /// set category(Category value) => setDirectusModel('category', value);
  /// ```
  void setDirectusModel(String key, DirectusModel value) {
    _data[key] = value.toJson();
  }

  /// Définit un modèle DirectusModel nested nullable
  void setDirectusModelOrNull(String key, DirectusModel? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.toJson();
    }
  }

  /// Définit une liste de modèles DirectusModel
  ///
  /// Exemple:
  /// ```dart
  /// set products(List<Product> value) => setDirectusModelList('products', value);
  /// ```
  void setDirectusModelList(String key, List<DirectusModel> value) {
    _data[key] = value.map((model) => model.toJson()).toList();
  }

  /// Définit une liste de modèles DirectusModel (nullable)
  void setDirectusModelListOrNull(String key, List<DirectusModel>? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.map((model) => model.toJson()).toList();
    }
  }

  /// Supprime une clé
  void remove(String key) {
    _data.remove(key);
  }

  // === Sérialisation ===

  /// Retourne les données JSON complètes
  Map<String, dynamic> toJson() => Map.from(_data);

  /// Retourne les données JSON sans les champs système
  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>.from(_data);
    map.remove('id');
    map.remove('date_created');
    map.remove('date_updated');
    map.remove('user_created');
    map.remove('user_updated');
    return map;
  }

  // === Helpers ===

  /// Registry des factories pour créer des instances de DirectusModel
  static final Map<Type, DirectusModel Function(Map<String, dynamic>)>
  _factories = {};

  /// Enregistre une factory pour un type de modèle
  ///
  /// Exemple:
  /// ```dart
  /// DirectusModel.registerFactory<Category>(
  ///   (data) => Category(data),
  /// );
  /// ```
  static void registerFactory<T extends DirectusModel>(
    DirectusModel Function(Map<String, dynamic>) factory,
  ) {
    _factories[T] = factory;
  }

  /// Supprime une factory
  static void unregisterFactory<T extends DirectusModel>() {
    _factories.remove(T);
  }

  /// Supprime toutes les factories
  static void clearFactories() {
    _factories.clear();
  }

  /// Retourne la factory pour un type donné (usage interne)
  static DirectusModel Function(Map<String, dynamic>)?
  getFactory<T extends DirectusModel>() {
    return _factories[T];
  }

  /// Crée une instance du type T depuis des données
  T _createInstance<T extends DirectusModel>(Map<String, dynamic> data) {
    final factory = _factories[T];
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Please register a factory using DirectusModel.registerFactory<$T>(...)',
      );
    }
    return factory(data) as T;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return itemName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectusModel &&
        other.runtimeType == runtimeType &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode ^ runtimeType.hashCode;
}

/// Implémentation concrète d'un modèle actif dynamique.
///
/// Utilisez `DynamicModel` lorsque vous souhaitez travailler avec
/// un `DirectusModel` sans créer une classe spécifique.
class DynamicModel extends DirectusModel {
  @override
  final String itemName;

  DynamicModel(super.data, {required this.itemName});

  DynamicModel.empty({required this.itemName}) : super.empty();
}
