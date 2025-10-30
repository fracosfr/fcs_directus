/// Système de property wrappers pour DirectusModel
///
/// Permet de simplifier l'accès aux propriétés avec une syntaxe unifiée.
///
/// Exemple d'utilisation:
/// ```dart
/// class Article extends DirectusModel {
///   late final title = stringValue('title');
///   late final price = doubleValue('price');
///   late final active = boolValue('active');
///
///   // Utilisation:
///   print(article.title);           // Lecture
///   article.title.set('Nouveau');   // Écriture
///   print(article.title.name);      // "title"
/// }
/// ```

import 'directus_model.dart';

/// Classe de base pour les property wrappers
abstract class DirectusProperty<T> {
  final DirectusModel _model;
  final String name;

  DirectusProperty(this._model, this.name);

  /// Récupère la valeur
  T get value;

  /// Définit la valeur
  void set(T value);

  /// Supprime la valeur
  void remove() => _model.remove(name);

  /// Vérifie si la valeur existe
  bool get exists => _model.has(name);

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectusProperty<T> &&
        other.name == name &&
        other.value == value;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}

/// Property wrapper pour String
class StringProperty extends DirectusProperty<String> {
  final String defaultValue;

  StringProperty(super.model, super.name, {this.defaultValue = ''});

  @override
  String get value => _model.getString(name, defaultValue: defaultValue);

  @override
  void set(String value) => _model.setString(name, value);

  /// Version nullable
  String? get valueOrNull => _model.getStringOrNull(name);

  void setOrNull(String? value) => _model.setStringOrNull(name, value);

  // === Méthodes utilitaires ===

  /// Vide la chaîne (définit à une chaîne vide)
  void clear() => set('');

  /// Vérifie si la chaîne est vide
  bool get isEmpty => value.isEmpty;

  /// Vérifie si la chaîne n'est pas vide
  bool get isNotEmpty => value.isNotEmpty;

  /// Longueur de la chaîne
  int get length => value.length;

  /// Ajoute du texte à la fin
  void append(String text) => set(value + text);

  /// Ajoute du texte au début
  void prepend(String text) => set(text + value);

  /// Met en majuscules
  void toUpperCase() => set(value.toUpperCase());

  /// Met en minuscules
  void toLowerCase() => set(value.toLowerCase());

  /// Capitalise (première lettre en majuscule)
  void capitalize() {
    if (value.isEmpty) return;
    set(value[0].toUpperCase() + value.substring(1).toLowerCase());
  }

  /// Trim (supprime les espaces)
  void trim() => set(value.trim());

  /// Vérifie si contient une sous-chaîne
  bool contains(String substring) => value.contains(substring);

  /// Remplace une sous-chaîne
  void replace(String from, String to) => set(value.replaceAll(from, to));
}

/// Property wrapper pour int
class IntProperty extends DirectusProperty<int> {
  final int defaultValue;

  IntProperty(super.model, super.name, {this.defaultValue = 0});

  @override
  int get value => _model.getInt(name, defaultValue: defaultValue);

  @override
  void set(int value) => _model.setInt(name, value);

  /// Version nullable
  int? get valueOrNull => _model.getIntOrNull(name);

  void setOrNull(int? value) => _model.setIntOrNull(name, value);

  // === Méthodes utilitaires ===

  /// Incrémente de 1
  void increment() => set(value + 1);

  /// Décrémente de 1
  void decrement() => set(value - 1);

  /// Incrémente de n
  void incrementBy(int n) => set(value + n);

  /// Décrémente de n
  void decrementBy(int n) => set(value - n);

  /// Multiplie par n
  void multiplyBy(int n) => set(value * n);

  /// Divise par n (division entière)
  void divideBy(int n) => set(value ~/ n);

  /// Remet à zéro
  void reset() => set(defaultValue);

  /// Définit au minimum entre la valeur actuelle et max
  void clampMax(int max) => set(value > max ? max : value);

  /// Définit au maximum entre la valeur actuelle et min
  void clampMin(int min) => set(value < min ? min : value);

  /// Limite la valeur entre min et max
  void clamp(int min, int max) => set(value.clamp(min, max));

  /// Vérifie si la valeur est positive
  bool get isPositive => value > 0;

  /// Vérifie si la valeur est négative
  bool get isNegative => value < 0;

  /// Vérifie si la valeur est zéro
  bool get isZero => value == 0;

  /// Prend la valeur absolue
  void abs() => set(value.abs());
}

/// Property wrapper pour double
class DoubleProperty extends DirectusProperty<double> {
  final double defaultValue;

  DoubleProperty(super.model, super.name, {this.defaultValue = 0.0});

  @override
  double get value => _model.getDouble(name, defaultValue: defaultValue);

  @override
  void set(double value) => _model.setDouble(name, value);

  /// Version nullable
  double? get valueOrNull => _model.getDoubleOrNull(name);

  void setOrNull(double? value) => _model.setDoubleOrNull(name, value);

  // === Méthodes utilitaires ===

  /// Incrémente de 1.0
  void increment() => set(value + 1.0);

  /// Décrémente de 1.0
  void decrement() => set(value - 1.0);

  /// Incrémente de n
  void incrementBy(double n) => set(value + n);

  /// Décrémente de n
  void decrementBy(double n) => set(value - n);

  /// Multiplie par n
  void multiplyBy(double n) => set(value * n);

  /// Divise par n
  void divideBy(double n) => set(value / n);

  /// Remet à la valeur par défaut
  void reset() => set(defaultValue);

  /// Limite la valeur entre min et max
  void clamp(double min, double max) => set(value.clamp(min, max));

  /// Arrondit à l'entier le plus proche
  void round() => set(value.roundToDouble());

  /// Arrondit vers le haut
  void ceil() => set(value.ceilToDouble());

  /// Arrondit vers le bas
  void floor() => set(value.floorToDouble());

  /// Tronque (supprime la partie décimale)
  void truncate() => set(value.truncateToDouble());

  /// Prend la valeur absolue
  void abs() => set(value.abs());

  /// Vérifie si la valeur est positive
  bool get isPositive => value > 0;

  /// Vérifie si la valeur est négative
  bool get isNegative => value < 0;

  /// Vérifie si la valeur est zéro
  bool get isZero => value == 0;

  /// Formate avec n décimales
  String toStringAsFixed(int decimals) => value.toStringAsFixed(decimals);
}

/// Property wrapper pour bool
class BoolProperty extends DirectusProperty<bool> {
  final bool defaultValue;

  BoolProperty(super.model, super.name, {this.defaultValue = false});

  @override
  bool get value => _model.getBool(name, defaultValue: defaultValue);

  @override
  void set(bool value) => _model.setBool(name, value);

  /// Version nullable
  bool? get valueOrNull => _model.getBoolOrNull(name);

  void setOrNull(bool? value) => _model.setBoolOrNull(name, value);

  // === Méthodes utilitaires ===

  /// Définit à true
  void setTrue() => set(true);

  /// Définit à false
  void setFalse() => set(false);

  /// Inverse la valeur (toggle)
  void toggle() => set(!value);

  /// Remet à la valeur par défaut
  void reset() => set(defaultValue);
}

/// Property wrapper pour DateTime
class DateTimeProperty extends DirectusProperty<DateTime?> {
  DateTimeProperty(super.model, super.name);

  @override
  DateTime? get value => _model.getDateTime(name);

  @override
  void set(DateTime? value) =>
      value == null ? _model.remove(name) : _model.setDateTime(name, value);

  /// Version non-nullable avec une valeur par défaut
  DateTime valueOr(DateTime defaultValue) => value ?? defaultValue;

  // === Méthodes utilitaires ===

  /// Définit à maintenant
  void setNow() => set(DateTime.now());

  /// Définit à aujourd'hui à minuit
  void setToday() {
    final now = DateTime.now();
    set(DateTime(now.year, now.month, now.day));
  }

  /// Ajoute des jours
  void addDays(int days) {
    final current = value;
    if (current != null) {
      set(current.add(Duration(days: days)));
    }
  }

  /// Ajoute des heures
  void addHours(int hours) {
    final current = value;
    if (current != null) {
      set(current.add(Duration(hours: hours)));
    }
  }

  /// Ajoute des minutes
  void addMinutes(int minutes) {
    final current = value;
    if (current != null) {
      set(current.add(Duration(minutes: minutes)));
    }
  }

  /// Vérifie si c'est dans le passé
  bool get isPast {
    final val = value;
    return val != null && val.isBefore(DateTime.now());
  }

  /// Vérifie si c'est dans le futur
  bool get isFuture {
    final val = value;
    return val != null && val.isAfter(DateTime.now());
  }

  /// Vérifie si c'est aujourd'hui
  bool get isToday {
    final val = value;
    if (val == null) return false;
    final now = DateTime.now();
    return val.year == now.year && val.month == now.month && val.day == now.day;
  }

  /// Formate la date
  String format(String pattern) {
    final val = value;
    if (val == null) return '';
    // Format basique (peut être étendu avec intl package)
    return val.toIso8601String();
  }
}

/// Property wrapper pour List
class ListProperty<T> extends DirectusProperty<List<T>> {
  ListProperty(super.model, super.name);

  @override
  List<T> get value => _model.getList<T>(name);

  @override
  void set(List<T> value) => _model.setList<T>(name, value);

  /// Ajoute un élément
  void add(T item) {
    final list = value.toList();
    list.add(item);
    set(list);
  }

  /// Supprime un élément
  void removeItem(T item) {
    final list = value.toList();
    list.remove(item);
    set(list);
  }

  /// Vide la liste
  void clear() => set([]);

  /// Taille de la liste
  int get length => value.length;

  /// Liste vide?
  bool get isEmpty => value.isEmpty;

  bool get isNotEmpty => value.isNotEmpty;
}

/// Property wrapper pour Map
class ObjectProperty extends DirectusProperty<Map<String, dynamic>?> {
  ObjectProperty(super.model, super.name);

  @override
  Map<String, dynamic>? get value => _model.getObject(name);

  @override
  void set(Map<String, dynamic>? value) =>
      value == null ? _model.remove(name) : _model.setObject(name, value);

  /// Version non-nullable avec une Map vide par défaut
  Map<String, dynamic> get valueOrEmpty => value ?? {};
}

/// Property wrapper pour DirectusModel nested
class ModelProperty<T extends DirectusModel> extends DirectusProperty<T?> {
  ModelProperty(super.model, super.name);

  @override
  T? get value => _model.getDirectusModelOrNull<T>(name);

  @override
  void set(T? value) => _model.setDirectusModelOrNull(name, value);

  /// Définit l'ID directement (utile pour les relations Many-to-One)
  ///
  /// Exemple :
  /// ```dart
  /// user.role.setById('role-id-123');
  /// ```
  void setById(String? id) {
    if (id == null) {
      _model.remove(name);
    } else {
      _model.setString(name, id);
    }
  }

  /// Version non-nullable qui lève une exception si null
  T get valueOrThrow {
    final val = value;
    if (val == null) {
      throw StateError('Field "$name" is null or does not exist');
    }
    return val;
  }
}

/// Property wrapper pour List<DirectusModel>
class ModelListProperty<T extends DirectusModel>
    extends DirectusProperty<List<T>> {
  ModelListProperty(super.model, super.name);

  @override
  List<T> get value => _model.getDirectusModelList<T>(name);

  @override
  void set(List<T> value) => _model.setDirectusModelList(name, value);

  /// Définit la liste d'IDs directement (utile pour les relations Many-to-Many)
  ///
  /// Exemple :
  /// ```dart
  /// user.policies.setByIds(['policy-1', 'policy-2']);
  /// ```
  void setByIds(List<String> ids) {
    _model.setList<String>(name, ids);
  }

  /// Ajoute un modèle
  void add(T item) {
    final list = value.toList();
    list.add(item);
    set(list);
  }

  /// Supprime un modèle
  void removeItem(T item) {
    final list = value.toList();
    list.remove(item);
    set(list);
  }

  /// Vide la liste
  void clear() => set([]);

  /// Taille de la liste
  int get length => value.length;

  /// Liste vide?
  bool get isEmpty => value.isEmpty;

  bool get isNotEmpty => value.isNotEmpty;
}

/// Import requis pour DirectusModel
// Import déplacé en haut du fichier
