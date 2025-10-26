import 'directus_model.dart';

/// Builder pour construire facilement des modèles Directus depuis JSON.
///
/// Cette classe simplifie la création de modèles en fournissant des getters
/// type-safe pour extraire les données JSON.
///
/// Exemple d'utilisation:
/// ```dart
/// class Article extends DirectusModel {
///   final String title;
///   final String? content;
///   final int viewCount;
///
///   Article._({
///     super.id,
///     required this.title,
///     this.content,
///     required this.viewCount,
///     super.dateCreated,
///     super.dateUpdated,
///   });
///
///   factory Article.fromJson(Map<String, dynamic> json) {
///     final builder = DirectusModelBuilder(json);
///     return Article._(
///       id: builder.id,
///       title: builder.getString('title'),
///       content: builder.getStringOrNull('content'),
///       viewCount: builder.getInt('view_count', defaultValue: 0),
///       dateCreated: builder.dateCreated,
///       dateUpdated: builder.dateUpdated,
///     );
///   }
///
///   @override
///   Map<String, dynamic> toMap() => {
///     'title': title,
///     if (content != null) 'content': content,
///     'view_count': viewCount,
///   };
/// }
/// ```
class DirectusModelBuilder {
  final Map<String, dynamic> _json;

  DirectusModelBuilder(this._json);

  /// Récupère l'ID depuis JSON
  String? get id => DirectusModel.parseId(_json['id']);

  /// Récupère la date de création depuis JSON
  DateTime? get dateCreated => DirectusModel.parseDate(_json['date_created']);

  /// Récupère la date de mise à jour depuis JSON
  DateTime? get dateUpdated => DirectusModel.parseDate(_json['date_updated']);

  /// Récupère l'utilisateur créateur depuis JSON
  String? get userCreated => DirectusModel.parseId(_json['user_created']);

  /// Récupère l'utilisateur modificateur depuis JSON
  String? get userUpdated => DirectusModel.parseId(_json['user_updated']);

  // Getters pour String
  String getString(String key, {String? defaultValue}) {
    final value = _json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Required field "$key" is missing');
    }
    return value.toString();
  }

  String? getStringOrNull(String key) {
    final value = _json[key];
    return value?.toString();
  }

  // Getters pour int
  int getInt(String key, {int? defaultValue}) {
    final value = _json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Required field "$key" is missing');
    }
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  int? getIntOrNull(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    try {
      return int.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  // Getters pour double
  double getDouble(String key, {double? defaultValue}) {
    final value = _json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Required field "$key" is missing');
    }
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }

  double? getDoubleOrNull(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  // Getters pour bool
  bool getBool(String key, {bool? defaultValue}) {
    final value = _json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Required field "$key" is missing');
    }
    if (value is bool) return value;
    if (value is int) return value != 0;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 'yes';
  }

  bool? getBoolOrNull(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 'yes';
  }

  // Getters pour DateTime
  DateTime getDateTime(String key) {
    final value = _json[key];
    if (value == null) {
      throw Exception('Required field "$key" is missing');
    }
    final parsed = DirectusModel.parseDate(value);
    if (parsed == null) {
      throw Exception('Invalid date format for field "$key"');
    }
    return parsed;
  }

  DateTime? getDateTimeOrNull(String key) {
    final value = _json[key];
    return DirectusModel.parseDate(value);
  }

  // Getters pour List
  List<T> getList<T>(
    String key,
    T Function(dynamic) mapper, {
    List<T>? defaultValue,
  }) {
    final value = _json[key];
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Required field "$key" is missing');
    }
    if (value is! List) {
      throw Exception('Field "$key" is not a list');
    }
    return value.map(mapper).toList();
  }

  List<T>? getListOrNull<T>(String key, T Function(dynamic) mapper) {
    final value = _json[key];
    if (value == null || value is! List) return null;
    return value.map(mapper).toList();
  }

  // Getter pour objet nested
  T getObject<T>(String key, T Function(Map<String, dynamic>) factory) {
    final value = _json[key];
    if (value == null) {
      throw Exception('Required field "$key" is missing');
    }
    if (value is! Map<String, dynamic>) {
      throw Exception('Field "$key" is not an object');
    }
    return factory(value);
  }

  T? getObjectOrNull<T>(String key, T Function(Map<String, dynamic>) factory) {
    final value = _json[key];
    if (value == null || value is! Map<String, dynamic>) return null;
    return factory(value);
  }

  // Getter générique
  T? get<T>(String key) {
    return _json[key] as T?;
  }

  // Vérifie si un champ existe
  bool has(String key) {
    return _json.containsKey(key);
  }

  // Récupère la map brute
  Map<String, dynamic> get raw => _json;
}

/// Builder pour construire facilement des Map depuis des modèles Directus.
///
/// Cette classe simplifie la construction de Map en fournissant des méthodes
/// pour ajouter conditionnellement des champs.
///
/// Exemple d'utilisation:
/// ```dart
/// @override
/// Map<String, dynamic> toMap() {
///   return DirectusMapBuilder()
///     .add('title', title)
///     .addIfNotNull('content', content)
///     .add('status', status)
///     .add('view_count', viewCount)
///     .build();
/// }
/// ```
class DirectusMapBuilder {
  final Map<String, dynamic> _map = {};

  /// Ajoute un champ
  DirectusMapBuilder add(String key, dynamic value) {
    _map[key] = value;
    return this;
  }

  /// Ajoute un champ seulement si la valeur n'est pas null
  DirectusMapBuilder addIfNotNull(String key, dynamic value) {
    if (value != null) {
      _map[key] = value;
    }
    return this;
  }

  /// Ajoute un champ seulement si la condition est vraie
  DirectusMapBuilder addIf(bool condition, String key, dynamic value) {
    if (condition) {
      _map[key] = value;
    }
    return this;
  }

  /// Ajoute tous les champs d'une autre map
  DirectusMapBuilder addAll(Map<String, dynamic> other) {
    _map.addAll(other);
    return this;
  }

  /// Ajoute une relation (seulement l'ID)
  DirectusMapBuilder addRelation(String key, DirectusModel? model) {
    if (model?.id != null) {
      _map[key] = model!.id;
    }
    return this;
  }

  /// Construit et retourne la Map
  Map<String, dynamic> build() => _map;
}
