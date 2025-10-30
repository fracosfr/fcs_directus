/// Directus Deep Query System
///
/// This library provides a type-safe, intuitive way to construct deep queries
/// for loading nested relations in Directus. Instead of manually creating
/// complex Map structures, you can use the fluent Deep API.
///
/// Example:
/// ```dart
/// final query = QueryParameters(
///   deep: Deep({
///     'author': DeepQuery().fields(['name', 'email']),
///     'categories': DeepQuery().limit(5).sort('name'),
///   }),
/// );
/// ```
library;

/// Abstract base class for deep query configuration
abstract class Deep {
  /// Convert this deep configuration to a JSON-serializable map
  Map<String, dynamic> toJson();

  /// Create a deep query with field-based configuration
  factory Deep(Map<String, DeepQuery> fields) = DeepFields;

  /// Create a deep query with simple depth limit
  factory Deep.maxDepth(int depth) = DeepMaxDepth;
}

/// Deep query configuration using field-based approach
class DeepFields implements Deep {
  final Map<String, DeepQuery> _fields;

  DeepFields(this._fields);

  @override
  Map<String, dynamic> toJson() {
    return _fields.map((key, value) => MapEntry(key, value.toJson()));
  }
}

/// Deep query with maximum depth limit
class DeepMaxDepth implements Deep {
  final int depth;

  DeepMaxDepth(this.depth);

  @override
  Map<String, dynamic> toJson() {
    return {'_limit': depth};
  }
}

/// Configuration for a single deep relation field
class DeepQuery {
  Map<String, dynamic>? _filter;
  List<String>? _fields;
  int? _limit;
  List<String>? _sort;
  Map<String, DeepQuery>? _deep;

  /// Create an empty deep query
  DeepQuery();

  /// Add a filter to this relation
  /// Can accept either a Filter object or a Map
  DeepQuery filter(dynamic filter) {
    if (filter is Map<String, dynamic>) {
      _filter = filter;
    } else if (filter != null) {
      // Assuming the filter has a toJson() method
      _filter = (filter as dynamic).toJson();
    }
    return this;
  }

  /// Specify which fields to return for this relation
  DeepQuery fields(List<String> fields) {
    _fields = fields;
    return this;
  }

  /// Limit the number of items returned
  DeepQuery limit(int limit) {
    _limit = limit;
    return this;
  }

  /// Sort the results
  /// Use '-' prefix for descending order, e.g., '-created_at'
  DeepQuery sort(dynamic sort) {
    if (sort is String) {
      _sort = [sort];
    } else if (sort is List<String>) {
      _sort = sort;
    }
    return this;
  }

  /// Add nested deep queries for relations within this relation
  DeepQuery deep(Map<String, DeepQuery> deepQueries) {
    _deep = deepQueries;
    return this;
  }

  /// Convert to JSON format expected by Directus
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (_filter != null) {
      json['_filter'] = _filter;
    }

    if (_fields != null) {
      json['_fields'] = _fields;
    }

    if (_limit != null) {
      json['_limit'] = _limit;
    }

    if (_sort != null) {
      json['_sort'] = _sort;
    }

    if (_deep != null) {
      final deepJson = _deep!.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      json.addAll(deepJson);
    }

    return json;
  }
}

/// Extension methods for more intuitive deep query building
extension DeepQueryExtensions on DeepQuery {
  /// Select all fields for this relation
  DeepQuery allFields() {
    _fields = ['*'];
    return this;
  }

  /// Sort in ascending order
  DeepQuery sortAsc(String field) {
    _sort = [field];
    return this;
  }

  /// Sort in descending order
  DeepQuery sortDesc(String field) {
    _sort = ['-$field'];
    return this;
  }

  /// Limit to first N items
  DeepQuery first(int n) {
    _limit = n;
    return this;
  }
}
