import 'directus_property.dart';

/// Modèle Directus avec stockage JSON interne (Active Record pattern).
///
/// Cette approche stocke les données JSON directement dans l'objet
/// et fournit des méthodes typées pour y accéder et les modifier.
///
/// Exemple d'utilisation classique:
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
/// ```
///
/// Exemple avec property wrappers (simplifié):
/// ```dart
/// class Product extends DirectusModel {
///   Product(super.data);
///
///   @override
///   String get itemName => 'products';
///
///   late final name = stringValue('name');
///   late final price = doubleValue('price');
///
///   // Utilisation:
///   // print(product.name);        // Lecture
///   // product.name.set('Laptop'); // Écriture
///   // print(product.name.name);   // "name"
/// }
/// ```
abstract class DirectusModel {
  /// Données JSON internes (état actuel)
  final Map<String, dynamic> _data;

  /// Données originales (état initial, pour tracking des modifications)
  final Map<String, dynamic> _originalData;

  /// Champs qui ont été modifiés depuis la création/chargement
  final Set<String> _dirtyFields = {};

  /// Nom de la collection Directus
  String get itemName;

  /// Crée un modèle depuis des données JSON
  DirectusModel(Map<String, dynamic> data)
    : _data = Map.from(data),
      _originalData = Map.from(data);

  /// Crée un modèle vide
  DirectusModel.empty() : _data = {}, _originalData = {};

  // === Champs standards Directus ===

  /// Identifiant unique
  String? get id => _data['id']?.toString();
  set id(String? value) {
    if (value == null) {
      _data.remove('id');
    } else {
      _data['id'] = value;
    }
    _dirtyFields.add('id');
  }

  /// Date de création
  DateTime? get dateCreated => _parseDate(_data['date_created']);
  set dateCreated(DateTime? value) {
    if (value == null) {
      _data.remove('date_created');
    } else {
      _data['date_created'] = value.toIso8601String();
    }
    _dirtyFields.add('date_created');
  }

  /// Date de dernière modification
  DateTime? get dateUpdated => _parseDate(_data['date_updated']);
  set dateUpdated(DateTime? value) {
    if (value == null) {
      _data.remove('date_updated');
    } else {
      _data['date_updated'] = value.toIso8601String();
    }
    _dirtyFields.add('date_updated');
  }

  DateTime? get lastUpdate => dateUpdated ?? dateCreated;

  /// Utilisateur créateur
  String? get userCreated => _data['user_created']?.toString();
  set userCreated(String? value) {
    if (value == null) {
      _data.remove('user_created');
    } else {
      _data['user_created'] = value;
    }
    _dirtyFields.add('user_created');
  }

  /// Utilisateur modificateur
  String? get userUpdated => _data['user_updated']?.toString();
  set userUpdated(String? value) {
    if (value == null) {
      _data.remove('user_updated');
    } else {
      _data['user_updated'] = value;
    }
    _dirtyFields.add('user_updated');
  }

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

  /// Récupère une valeur JSON dynamique
  ///
  /// Retourne la valeur brute telle qu'elle est stockée (dynamic).
  /// Peut être utilisé pour des valeurs JSON de tout type :
  /// String, int, double, bool, Map, List, null.
  dynamic getJson(String key) {
    return _data[key];
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
    _dirtyFields.add(key);
  }

  /// Définit une valeur String nullable
  void setStringOrNull(String key, String? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _dirtyFields.add(key);
  }

  /// Définit une valeur int
  void setInt(String key, int value) {
    _data[key] = value;
    _dirtyFields.add(key);
  }

  /// Définit une valeur int nullable
  void setIntOrNull(String key, int? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _dirtyFields.add(key);
  }

  /// Définit une valeur double
  void setDouble(String key, double value) {
    _data[key] = value;
    _dirtyFields.add(key);
  }

  /// Définit une valeur double nullable
  void setDoubleOrNull(String key, double? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _dirtyFields.add(key);
  }

  /// Définit une valeur bool
  void setBool(String key, bool value) {
    _data[key] = value;
    _dirtyFields.add(key);
  }

  /// Définit une valeur bool nullable
  void setBoolOrNull(String key, bool? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _dirtyFields.add(key);
  }

  /// Définit une valeur DateTime
  void setDateTime(String key, DateTime value) {
    _data[key] = value.toIso8601String();
    _dirtyFields.add(key);
  }

  /// Définit une valeur DateTime nullable
  void setDateTimeOrNull(String key, DateTime? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.toIso8601String();
    }
    _dirtyFields.add(key);
  }

  /// Définit une liste
  void setList<T>(String key, List<T> value) {
    _data[key] = value;
    _dirtyFields.add(key);
  }

  /// Définit un objet nested
  void setObject(String key, Map<String, dynamic> value) {
    _data[key] = value;
    _dirtyFields.add(key);
  }

  /// Définit une valeur JSON dynamique
  ///
  /// Accepte n'importe quel type de valeur JSON :
  /// String, int, double, bool, Map, List, null.
  void setJson(String key, dynamic value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
    _dirtyFields.add(key);
  }

  /// Définit un modèle DirectusModel nested
  ///
  /// Exemple:
  /// ```dart
  /// set category(Category value) => setDirectusModel('category', value);
  /// ```
  void setDirectusModel(String key, DirectusModel value) {
    _data[key] = value.toJson();
    _dirtyFields.add(key);
  }

  /// Définit un modèle DirectusModel nested nullable
  void setDirectusModelOrNull(String key, DirectusModel? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.toJson();
    }
    _dirtyFields.add(key);
  }

  /// Définit une liste de modèles DirectusModel
  ///
  /// Exemple:
  /// ```dart
  /// set products(List<Product> value) => setDirectusModelList('products', value);
  /// ```
  void setDirectusModelList(String key, List<DirectusModel> value) {
    _data[key] = value.map((model) => model.toJson()).toList();
    _dirtyFields.add(key);
  }

  /// Définit une liste de modèles DirectusModel (nullable)
  void setDirectusModelListOrNull(String key, List<DirectusModel>? value) {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value.map((model) => model.toJson()).toList();
    }
    _dirtyFields.add(key);
  }

  /// Supprime une clé
  void remove(String key) {
    _data.remove(key);
    _dirtyFields.add(key);
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

  /// Retourne uniquement les champs qui ont été modifiés
  ///
  /// Utilisé pour les opérations UPDATE afin d'envoyer uniquement
  /// les modifications à Directus.
  ///
  /// Pour les relations (Many-to-One et Many-to-Many), si le champ
  /// a été modifié et contient un objet complet, seul l'ID sera inclus.
  ///
  /// Exemple:
  /// ```dart
  /// final user = DirectusUser(await users.getUser('123'));
  /// // _dirtyFields = {}
  ///
  /// user.firstName.set('Jean');
  /// // _dirtyFields = {'first_name'}
  ///
  /// user.role.setById('role-456');
  /// // _dirtyFields = {'first_name', 'role'}
  ///
  /// await users.updateUser(user.id!, user.toJsonDirty());
  /// // Envoie seulement: {"first_name": "Jean", "role": "role-456"}
  /// ```
  Map<String, dynamic> toJsonDirty() {
    final dirty = <String, dynamic>{};

    for (final key in _dirtyFields) {
      if (!_data.containsKey(key)) {
        // Le champ a été supprimé
        continue;
      }

      final value = _data[key];

      // Si c'est un objet avec un 'id', c'est probablement une relation
      // On n'envoie que l'ID pour les relations Many-to-One
      if (value is Map<String, dynamic> && value.containsKey('id')) {
        dirty[key] = value['id'];
      }
      // Si c'est une liste d'objets avec 'id', c'est une relation Many-to-Many
      else if (value is List && value.isNotEmpty && value.first is Map) {
        final firstItem = value.first as Map<String, dynamic>;
        if (firstItem.containsKey('id')) {
          // Extraire uniquement les IDs
          dirty[key] = value
              .map((item) => (item as Map<String, dynamic>)['id'])
              .where((id) => id != null)
              .toList();
        } else {
          dirty[key] = value;
        }
      } else {
        dirty[key] = value;
      }
    }

    return dirty;
  }

  // === Gestion du dirty tracking ===

  /// Vérifie si le modèle a des modifications non sauvegardées
  bool get isDirty => _dirtyFields.isNotEmpty;

  /// Vérifie si un champ spécifique a été modifié
  bool isDirtyField(String key) => _dirtyFields.contains(key);

  /// Retourne la liste des champs modifiés
  Set<String> get dirtyFields => Set.from(_dirtyFields);

  /// Marque le modèle comme "propre" (pas de modifications)
  ///
  /// À appeler après une sauvegarde réussie vers Directus.
  ///
  /// Exemple:
  /// ```dart
  /// user.firstName.set('Jean');
  /// await users.updateUser(user.id!, user.toJsonDirty());
  /// user.markClean();  // Réinitialise le tracking
  /// ```
  void markClean() {
    _dirtyFields.clear();
    _originalData.clear();
    _originalData.addAll(_data);
  }

  /// Annule toutes les modifications et restaure les données originales
  ///
  /// Exemple:
  /// ```dart
  /// user.firstName.set('Jean');
  /// user.lastName.set('Dupont');
  /// print(user.isDirty);  // true
  ///
  /// user.revert();
  /// print(user.isDirty);  // false
  /// print(user.firstName.value);  // Valeur originale restaurée
  /// ```
  void revert() {
    _data.clear();
    _data.addAll(_originalData);
    _dirtyFields.clear();
  }

  /// Retourne la valeur originale d'un champ (avant modifications)
  ///
  /// Retourne null si le champ n'existait pas dans les données originales.
  dynamic getOriginalValue(String key) => _originalData[key];

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

  /// Crée une instance du type T depuis des données (méthode publique)
  ///
  /// Utilisée par les property wrappers pour créer des instances de modèles.
  static T createInstance<T extends DirectusModel>(Map<String, dynamic> data) {
    final factory = _factories[T];
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Please register a factory using DirectusModel.registerFactory<$T>(...)',
      );
    }
    return factory(data) as T;
  }

  /// Crée une instance du type T depuis des données (méthode interne)
  T _createInstance<T extends DirectusModel>(Map<String, dynamic> data) {
    return DirectusModel.createInstance<T>(data);
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

  // === Property Wrappers Factory Methods ===

  /// Crée un property wrapper pour String
  ///
  /// Exemple:
  /// ```dart
  /// late final name = stringValue('name');
  /// print(name);           // Lecture: product.name
  /// name.set('Laptop');    // Écriture
  /// print(name.name);      // "name"
  /// ```
  StringProperty stringValue(String key, {String defaultValue = ''}) {
    return StringProperty(this, key, defaultValue: defaultValue);
  }

  /// Crée un property wrapper pour int
  IntProperty intValue(String key, {int defaultValue = 0}) {
    return IntProperty(this, key, defaultValue: defaultValue);
  }

  /// Crée un property wrapper pour double
  DoubleProperty doubleValue(String key, {double defaultValue = 0.0}) {
    return DoubleProperty(this, key, defaultValue: defaultValue);
  }

  /// Crée un property wrapper pour bool
  BoolProperty boolValue(String key, {bool defaultValue = false}) {
    return BoolProperty(this, key, defaultValue: defaultValue);
  }

  /// Crée un property wrapper pour DateTime
  DateTimeProperty dateTimeValue(String key) {
    return DateTimeProperty(this, key);
  }

  /// Crée un property wrapper pour List
  ListProperty<T> listValue<T>(String key) {
    return ListProperty<T>(this, key);
  }

  /// Crée un property wrapper pour Map
  ObjectProperty objectValue(String key) {
    return ObjectProperty(this, key);
  }

  /// Crée un property wrapper pour valeur JSON dynamique
  ///
  /// Exemple:
  /// ```dart
  /// class Settings extends DirectusModel {
  ///   late final config = jsonValue('config');
  ///   late final metadata = jsonValue('metadata');
  ///
  ///   // Utilisation:
  ///   settings.config.set({'theme': 'dark', 'lang': 'fr'});
  ///   settings.metadata.set(['tag1', 'tag2', 'tag3']);
  ///
  ///   final theme = settings.config.asMap()?['theme'];
  ///   final tags = settings.metadata.asList();
  /// }
  /// ```
  JsonProperty jsonValue(String key) {
    return JsonProperty(this, key);
  }

  /// Crée un property wrapper pour Enum
  ///
  /// Convertit automatiquement entre String (Directus) et Enum (Dart).
  /// Si la valeur String ne correspond à aucune valeur de l'enum,
  /// la valeur par défaut est utilisée.
  ///
  /// **IMPORTANT:** Vous devez passer **toutes les valeurs de l'enum**
  /// via le paramètre `values` (utilisez `EnumType.values`).
  ///
  /// Exemple:
  /// ```dart
  /// enum Status { draft, published, archived }
  ///
  /// class Article extends DirectusModel {
  ///   Article(super.data);
  ///
  ///   @override
  ///   String get itemName => 'articles';
  ///
  ///   late final status = enumValue<Status>(
  ///     'status',
  ///     Status.draft,      // Valeur par défaut
  ///     Status.values,     // Toutes les valeurs de l'enum
  ///   );
  ///
  ///   // Utilisation:
  ///   print(article.status.value);        // Status.published
  ///   article.status.set(Status.draft);
  ///   print(article.status.asString);     // "draft"
  ///
  ///   if (article.status.is_(Status.published)) {
  ///     print('Article publié !');
  ///   }
  /// }
  /// ```
  EnumProperty<T> enumValue<T extends Enum>(
    String key,
    T defaultValue,
    List<T> values,
  ) {
    return EnumProperty<T>(this, key, defaultValue, values);
  }

  /// Crée un property wrapper pour DirectusModel nested
  ModelProperty<T> modelValue<T extends DirectusModel>(String key) {
    return ModelProperty<T>(this, key);
  }

  /// Crée un property wrapper pour `List<DirectusModel>`
  ModelListProperty<T> modelListValue<T extends DirectusModel>(String key) {
    return ModelListProperty<T>(this, key);
  }

  /// Crée un property wrapper pour `List<DirectusModel>` dans une relation Many-to-Many
  ///
  /// Extrait automatiquement les modèles du champ spécifié dans la table de jonction.
  ///
  /// Exemple avec les policies d'un utilisateur :
  /// ```dart
  /// class DirectusUser extends DirectusModel {
  ///   DirectusUser(super.data);
  ///
  ///   @override
  ///   String get itemName => 'directus_users';
  ///
  ///   // La table de jonction directus_users_policies contient:
  ///   // {directus_users_id: '...', directus_policies_id: {...}}
  ///   //
  ///   // On veut récupérer directement les DirectusPolicy sans manipuler la table de jonction
  ///   late final policies = modelListValueM2M<DirectusPolicy>(
  ///     'policies',                  // Nom du champ de la relation M2M
  ///     'directus_policies_id'       // Nom du champ dans la table de jonction
  ///   );
  ///
  ///   // Utilisation:
  ///   List<DirectusPolicy> policyList = user.policies.value;
  ///   DirectusPolicy firstPolicy = user.policies.first;
  ///
  ///   // Modification:
  ///   user.policies.setByIds(['policy-1', 'policy-2']);
  /// }
  /// ```
  ///
  /// **IMPORTANT:** Pour que cette méthode fonctionne, les relations doivent être
  /// chargées explicitement avec le paramètre `fields`:
  /// ```dart
  /// final user = await client.users.getUser(
  ///   userId,
  ///   query: QueryParameters(
  ///     fields: ['*', 'policies.directus_policies_id.*']
  ///   )
  /// );
  /// ```
  ModelListPropertyM2M<T> modelListValueM2M<T extends DirectusModel>(
    String key,
    String subKey,
  ) {
    return ModelListPropertyM2M<T>(this, key, subKey);
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, data: $_data)';
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
