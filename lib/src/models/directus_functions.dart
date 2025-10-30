/// Support for Directus functions in queries
///
/// This module provides a type-safe API for using functions in filters,
/// fields selections, and group by operations.
///
/// Example:
/// ```dart
/// // In filters
/// filter: Filter.field(Func.year('created_at')).equals(2024)
///
/// // In fields
/// fields: [Func.year('created_at'), 'title']
///
/// // In groupBy
/// groupBy: GroupBy.fields([Func.month('created_at')])
/// ```
library;

/// Helper class for Directus functions
///
/// Provides static methods to create function calls for date/time operations,
/// array operations, and relational counting.
class Func {
  /// Extract year from a date field
  ///
  /// Example:
  /// ```dart
  /// Func.year('date_created')
  /// // Returns: "year(date_created)"
  /// ```
  static String year(String field) => 'year($field)';

  /// Extract month from a date field (1-12)
  ///
  /// Example:
  /// ```dart
  /// Func.month('date_created')
  /// // Returns: "month(date_created)"
  /// ```
  static String month(String field) => 'month($field)';

  /// Extract week from a date field (1-53)
  ///
  /// Example:
  /// ```dart
  /// Func.week('date_created')
  /// // Returns: "week(date_created)"
  /// ```
  static String week(String field) => 'week($field)';

  /// Extract day of month from a date field (1-31)
  ///
  /// Example:
  /// ```dart
  /// Func.day('date_created')
  /// // Returns: "day(date_created)"
  /// ```
  static String day(String field) => 'day($field)';

  /// Extract day of week from a date field (0-6, Sunday = 0)
  ///
  /// Example:
  /// ```dart
  /// Func.weekday('date_created')
  /// // Returns: "weekday(date_created)"
  /// ```
  static String weekday(String field) => 'weekday($field)';

  /// Extract hour from a datetime field (0-23)
  ///
  /// Example:
  /// ```dart
  /// Func.hour('timestamp')
  /// // Returns: "hour(timestamp)"
  /// ```
  static String hour(String field) => 'hour($field)';

  /// Extract minute from a datetime field (0-59)
  ///
  /// Example:
  /// ```dart
  /// Func.minute('timestamp')
  /// // Returns: "minute(timestamp)"
  /// ```
  static String minute(String field) => 'minute($field)';

  /// Extract second from a datetime field (0-59)
  ///
  /// Example:
  /// ```dart
  /// Func.second('timestamp')
  /// // Returns: "second(timestamp)"
  /// ```
  static String second(String field) => 'second($field)';

  /// Count items in an array or JSON field
  ///
  /// Example:
  /// ```dart
  /// Func.count('tags')
  /// // Returns: "count(tags)"
  /// ```
  static String count(String field) => 'count($field)';
}

/// Dynamic variables for use in filters and queries
///
/// These variables are replaced by Directus at query time with actual values.
class DynamicVar {
  /// Current timestamp
  ///
  /// Example:
  /// ```dart
  /// Filter.field('expires_at').greaterThan(DynamicVar.now)
  /// ```
  static const String now = r'$NOW';

  /// Current timestamp (alias)
  static const String currentTimestamp = r'$NOW';

  /// Current user ID
  ///
  /// Example:
  /// ```dart
  /// Filter.field('user_id').equals(DynamicVar.currentUser)
  /// ```
  static const String currentUser = r'$CURRENT_USER';

  /// Current user's role ID
  ///
  /// Example:
  /// ```dart
  /// Filter.field('role').equals(DynamicVar.currentRole)
  /// ```
  static const String currentRole = r'$CURRENT_ROLE';

  /// Current user's policies
  ///
  /// Example:
  /// ```dart
  /// Filter.field('policies').in_([DynamicVar.currentPolicies])
  /// ```
  static const String currentPolicies = r'$CURRENT_POLICIES';
}
