/// Système de filtres type-safe pour les requêtes Directus.
///
/// Permet de construire des filtres complexes avec une API intuitive
/// sans avoir à connaître les opérateurs Directus (_eq, _neq, etc.)
///
/// Exemple d'utilisation:
/// ```dart
/// // Filtre simple
/// Filter.field('status').equals('published')
///
/// // Filtres combinés
/// Filter.and([
///   Filter.field('price').greaterThan(100),
///   Filter.field('stock').greaterThan(0),
/// ])
///
/// // Filtres imbriqués
/// Filter.or([
///   Filter.and([
///     Filter.field('category').equals('electronics'),
///     Filter.field('price').lessThan(500),
///   ]),
///   Filter.field('featured').equals(true),
/// ])
/// ```
abstract class Filter {
  /// Convertit le filtre en Map pour l'API Directus
  Map<String, dynamic> toJson();

  // === Constructeurs de champs ===

  /// Crée un filtre sur un champ spécifique
  static FieldFilter field(String fieldName) => FieldFilter(fieldName);

  // === Opérateurs logiques ===

  /// Combine plusieurs filtres avec un ET logique (tous doivent être vrais)
  static LogicalFilter and(List<Filter> filters) =>
      LogicalFilter._('_and', filters);

  /// Combine plusieurs filtres avec un OU logique (au moins un doit être vrai)
  static LogicalFilter or(List<Filter> filters) =>
      LogicalFilter._('_or', filters);

  // === Filtres de relation ===

  /// Filtre sur une relation (objet nested)
  static RelationFilter relation(String relationName) =>
      RelationFilter(relationName);

  /// Au moins un élément de la relation correspond (pour O2M)
  static RelationalFilter some(String relationName) =>
      RelationalFilter._('_some', relationName);

  /// Aucun élément de la relation ne correspond (pour O2M)
  static RelationalFilter none(String relationName) =>
      RelationalFilter._('_none', relationName);

  // === Helpers ===

  /// Crée un filtre vide (retourne tout)
  static EmptyFilter empty() => EmptyFilter();
}

/// Filtre sur un champ spécifique avec des opérateurs
class FieldFilter extends Filter {
  final String _fieldName;

  FieldFilter(this._fieldName);

  // === Opérateurs de comparaison ===

  /// Égal à (=)
  OperatorFilter equals(dynamic value) =>
      OperatorFilter(_fieldName, '_eq', value);

  /// Différent de (≠)
  OperatorFilter notEquals(dynamic value) =>
      OperatorFilter(_fieldName, '_neq', value);

  /// Inférieur à (<)
  OperatorFilter lessThan(dynamic value) =>
      OperatorFilter(_fieldName, '_lt', value);

  /// Inférieur ou égal à (≤)
  OperatorFilter lessThanOrEqual(dynamic value) =>
      OperatorFilter(_fieldName, '_lte', value);

  /// Supérieur à (>)
  OperatorFilter greaterThan(dynamic value) =>
      OperatorFilter(_fieldName, '_gt', value);

  /// Supérieur ou égal à (≥)
  OperatorFilter greaterThanOrEqual(dynamic value) =>
      OperatorFilter(_fieldName, '_gte', value);

  // === Opérateurs de collection ===

  /// Dans la liste (IN)
  OperatorFilter inList(List<dynamic> values) =>
      OperatorFilter(_fieldName, '_in', values);

  /// Pas dans la liste (NOT IN)
  OperatorFilter notInList(List<dynamic> values) =>
      OperatorFilter(_fieldName, '_nin', values);

  /// Entre deux valeurs (BETWEEN)
  OperatorFilter between(dynamic min, dynamic max) =>
      OperatorFilter(_fieldName, '_between', [min, max]);

  /// Pas entre deux valeurs (NOT BETWEEN)
  OperatorFilter notBetween(dynamic min, dynamic max) =>
      OperatorFilter(_fieldName, '_nbetween', [min, max]);

  // === Opérateurs de chaîne ===

  /// Contient (LIKE %value%)
  OperatorFilter contains(String value) =>
      OperatorFilter(_fieldName, '_contains', value);

  /// Ne contient pas (NOT LIKE %value%)
  OperatorFilter notContains(String value) =>
      OperatorFilter(_fieldName, '_ncontains', value);

  /// Commence par (LIKE value%)
  OperatorFilter startsWith(String value) =>
      OperatorFilter(_fieldName, '_starts_with', value);

  /// Ne commence pas par (NOT LIKE value%)
  OperatorFilter notStartsWith(String value) =>
      OperatorFilter(_fieldName, '_nstarts_with', value);

  /// Se termine par (LIKE %value)
  OperatorFilter endsWith(String value) =>
      OperatorFilter(_fieldName, '_ends_with', value);

  /// Ne se termine pas par (NOT LIKE %value)
  OperatorFilter notEndsWith(String value) =>
      OperatorFilter(_fieldName, '_nends_with', value);

  // === Opérateurs de chaîne (insensibles à la casse) ===

  /// Contient (insensible à la casse) (ILIKE %value%)
  OperatorFilter containsInsensitive(String value) =>
      OperatorFilter(_fieldName, '_icontains', value);

  /// Ne contient pas (insensible à la casse) (NOT ILIKE %value%)
  OperatorFilter notContainsInsensitive(String value) =>
      OperatorFilter(_fieldName, '_nicontains', value);

  /// Commence par (insensible à la casse) (ILIKE value%)
  OperatorFilter startsWithInsensitive(String value) =>
      OperatorFilter(_fieldName, '_istarts_with', value);

  /// Ne commence pas par (insensible à la casse) (NOT ILIKE value%)
  OperatorFilter notStartsWithInsensitive(String value) =>
      OperatorFilter(_fieldName, '_nistarts_with', value);

  /// Se termine par (insensible à la casse) (ILIKE %value)
  OperatorFilter endsWithInsensitive(String value) =>
      OperatorFilter(_fieldName, '_iends_with', value);

  /// Ne se termine pas par (insensible à la casse) (NOT ILIKE %value)
  OperatorFilter notEndsWithInsensitive(String value) =>
      OperatorFilter(_fieldName, '_niends_with', value);

  // === Opérateurs géographiques ===

  /// Intersecte avec une géométrie (pour champs geometry)
  OperatorFilter intersects(dynamic geometry) =>
      OperatorFilter(_fieldName, '_intersects', geometry);

  /// N'intersecte pas avec une géométrie
  OperatorFilter notIntersects(dynamic geometry) =>
      OperatorFilter(_fieldName, '_nintersects', geometry);

  /// Intersecte avec une boîte englobante (bounding box)
  OperatorFilter intersectsBBox(dynamic bbox) =>
      OperatorFilter(_fieldName, '_intersects_bbox', bbox);

  /// N'intersecte pas avec une boîte englobante
  OperatorFilter notIntersectsBBox(dynamic bbox) =>
      OperatorFilter(_fieldName, '_nintersects_bbox', bbox);

  // === Opérateurs de validation (pour formulaires) ===

  /// Correspond à une expression régulière
  OperatorFilter regex(String pattern) =>
      OperatorFilter(_fieldName, '_regex', pattern);

  /// Champ soumis (pour validation de formulaire)
  OperatorFilter submitted() => OperatorFilter(_fieldName, '_submitted', true);

  // === Opérateurs null ===

  /// Est null (IS NULL)
  OperatorFilter isNull() => OperatorFilter(_fieldName, '_null', true);

  /// N'est pas null (IS NOT NULL)
  OperatorFilter isNotNull() => OperatorFilter(_fieldName, '_nnull', true);

  /// Est vide (chaîne vide ou null)
  OperatorFilter isEmpty() => OperatorFilter(_fieldName, '_empty', true);

  /// N'est pas vide
  OperatorFilter isNotEmpty() => OperatorFilter(_fieldName, '_nempty', true);

  @override
  Map<String, dynamic> toJson() {
    throw UnsupportedError(
      'FieldFilter must be combined with an operator (e.g., .equals(), .greaterThan())',
    );
  }
}

/// Filtre avec un opérateur appliqué
class OperatorFilter extends Filter {
  final String _fieldName;
  final String _operator;
  final dynamic _value;

  OperatorFilter(this._fieldName, this._operator, this._value);

  @override
  Map<String, dynamic> toJson() {
    return {
      _fieldName: {_operator: _value},
    };
  }
}

/// Filtre logique (AND, OR)
class LogicalFilter extends Filter {
  final String _operator;
  final List<Filter> _filters;

  LogicalFilter._(this._operator, this._filters);

  @override
  Map<String, dynamic> toJson() {
    return {_operator: _filters.map((f) => f.toJson()).toList()};
  }
}

/// Filtre sur une relation
class RelationFilter extends Filter {
  final String _relationName;
  Filter? _filter;

  RelationFilter(this._relationName);

  /// Applique un filtre sur la relation
  RelationFilter where(Filter filter) {
    _filter = filter;
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    if (_filter == null) {
      throw UnsupportedError('RelationFilter must have a .where() clause');
    }
    return {_relationName: _filter!.toJson()};
  }
}

/// Filtre relationnel pour O2M (_some, _none)
class RelationalFilter extends Filter {
  final String _operator; // '_some' ou '_none'
  final String _relationName;
  Filter? _filter;

  RelationalFilter._(this._operator, this._relationName);

  /// Applique un filtre sur la relation
  RelationalFilter where(Filter filter) {
    _filter = filter;
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    if (_filter == null) {
      throw UnsupportedError('RelationalFilter must have a .where() clause');
    }
    return {
      _relationName: {_operator: _filter!.toJson()},
    };
  }
}

/// Filtre vide (ne filtre rien)
class EmptyFilter extends Filter {
  @override
  Map<String, dynamic> toJson() => {};
}

/// Extension pour ajouter .toFilter() sur `Map<String, dynamic>`
extension MapToFilter on Map<String, dynamic> {
  /// Convertit un Map en Filter (pour compatibilité ascendante)
  RawFilter toFilter() => RawFilter(this);
}

/// Filtre brut à partir d'un Map (pour compatibilité)
class RawFilter extends Filter {
  final Map<String, dynamic> _data;

  RawFilter(this._data);

  @override
  Map<String, dynamic> toJson() => _data;
}
