/// Support for Directus aggregation operations
///
/// This module provides a type-safe API for performing aggregations
/// on Directus collections, similar to the Filter and Deep systems.
///
/// Example:
/// ```dart
/// final result = await client.items('products').readMany(
///   query: QueryParameters(
///     aggregate: Aggregate()
///       ..count(['*'])
///       ..sum(['price', 'quantity'])
///       ..avg(['rating']),
///     groupBy: GroupBy.fields(['category']),
///   ),
/// );
/// ```

/// Aggregate operations for Directus queries
///
/// Provides a fluent API for building aggregation queries with type safety.
class Aggregate {
  final Map<String, List<String>> _operations = {};

  /// Count all items or specific fields
  ///
  /// Use '*' to count all items, or specify field names to count
  /// Example:
  /// ```dart
  /// aggregate.count(['*'])
  /// aggregate.count(['id', 'title'])
  /// ```
  Aggregate count(List<String> fields) {
    _operations['count'] = fields;
    return this;
  }

  /// Count distinct values in fields
  ///
  /// Example:
  /// ```dart
  /// aggregate.countDistinct(['category', 'author'])
  /// ```
  Aggregate countDistinct(List<String> fields) {
    _operations['countDistinct'] = fields;
    return this;
  }

  /// Count all items (optimized)
  ///
  /// Example:
  /// ```dart
  /// aggregate.countAll()
  /// ```
  Aggregate countAll() {
    _operations['countAll'] = ['*'];
    return this;
  }

  /// Sum values of numeric fields
  ///
  /// Example:
  /// ```dart
  /// aggregate.sum(['price', 'quantity'])
  /// ```
  Aggregate sum(List<String> fields) {
    _operations['sum'] = fields;
    return this;
  }

  /// Sum distinct values of numeric fields
  ///
  /// Example:
  /// ```dart
  /// aggregate.sumDistinct(['price'])
  /// ```
  Aggregate sumDistinct(List<String> fields) {
    _operations['sumDistinct'] = fields;
    return this;
  }

  /// Calculate average of numeric fields
  ///
  /// Example:
  /// ```dart
  /// aggregate.avg(['price', 'rating'])
  /// ```
  Aggregate avg(List<String> fields) {
    _operations['avg'] = fields;
    return this;
  }

  /// Calculate average of distinct values
  ///
  /// Example:
  /// ```dart
  /// aggregate.avgDistinct(['rating'])
  /// ```
  Aggregate avgDistinct(List<String> fields) {
    _operations['avgDistinct'] = fields;
    return this;
  }

  /// Find minimum values
  ///
  /// Example:
  /// ```dart
  /// aggregate.min(['price', 'stock'])
  /// ```
  Aggregate min(List<String> fields) {
    _operations['min'] = fields;
    return this;
  }

  /// Find maximum values
  ///
  /// Example:
  /// ```dart
  /// aggregate.max(['price', 'stock'])
  /// ```
  Aggregate max(List<String> fields) {
    _operations['max'] = fields;
    return this;
  }

  /// Convert to JSON format for Directus API
  Map<String, dynamic> toJson() {
    return Map.from(_operations);
  }

  /// Check if aggregate has any operations
  bool get isEmpty => _operations.isEmpty;

  /// Check if aggregate has operations
  bool get isNotEmpty => _operations.isNotEmpty;
}

/// GroupBy configuration for aggregation queries
///
/// Groups results by specified fields, optionally with date/time functions
abstract class GroupBy {
  /// Create a simple field-based grouping
  ///
  /// Example:
  /// ```dart
  /// GroupBy.fields(['category', 'status'])
  /// ```
  factory GroupBy.fields(List<String> fields) = GroupByFields;

  /// Convert to JSON format for Directus API
  List<String> toJson();
}

/// Simple field-based grouping
class GroupByFields implements GroupBy {
  final List<String> fields;

  GroupByFields(this.fields);

  @override
  List<String> toJson() => List.from(fields);
}
