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

/// Helper class for creating `$NOW` dynamic variable with time adjustments
///
/// Directus supports `$NOW` with optional time offset using the syntax:
/// `$NOW(<adjustment>)` where adjustment can be positive or negative.
///
/// Supported units: `year`, `years`, `month`, `months`, `week`, `weeks`,
/// `day`, `days`, `hour`, `hours`, `minute`, `minutes`, `second`, `seconds`
///
/// Examples:
/// ```dart
/// // Current timestamp
/// Now.value                    // "$NOW"
///
/// // With adjustments
/// Now.subtract(1, 'day')       // "$NOW(-1 day)"
/// Now.add(2, 'hours')          // "$NOW(+2 hours)"
/// Now.subtract(1, 'week')      // "$NOW(-1 week)"
/// Now.add(3, 'months')         // "$NOW(+3 months)"
///
/// // Convenience methods
/// Now.daysAgo(7)               // "$NOW(-7 days)"
/// Now.hoursAgo(24)             // "$NOW(-24 hours)"
/// Now.daysFromNow(30)          // "$NOW(+30 days)"
///
/// // In filters
/// Filter.field('expires_at').greaterThan(Now.value)
/// Filter.field('created_at').greaterThan(Now.daysAgo(7))
/// Filter.field('due_date').lessThan(Now.add(1, 'month'))
/// ```
class Now {
  /// Current timestamp without adjustment
  ///
  /// Returns `$NOW`
  static const String value = r'$NOW';

  /// Create a $NOW with a time adjustment
  ///
  /// [amount] The number of units (positive or negative)
  /// [unit] The time unit (year, month, week, day, hour, minute, second)
  ///
  /// Example:
  /// ```dart
  /// Now.offset(-1, 'day')   // "$NOW(-1 day)"
  /// Now.offset(2, 'hours')  // "$NOW(+2 hours)"
  /// Now.offset(-3, 'weeks') // "$NOW(-3 weeks)"
  /// ```
  static String offset(int amount, String unit) {
    final sign = amount >= 0 ? '+' : '';
    return '\$NOW($sign$amount $unit)';
  }

  /// Subtract time from now
  ///
  /// [amount] The positive number of units to subtract
  /// [unit] The time unit (year, month, week, day, hour, minute, second)
  ///
  /// Example:
  /// ```dart
  /// Now.subtract(1, 'day')    // "$NOW(-1 day)"
  /// Now.subtract(2, 'weeks')  // "$NOW(-2 weeks)"
  /// Now.subtract(6, 'months') // "$NOW(-6 months)"
  /// ```
  static String subtract(int amount, String unit) {
    return '\$NOW(-$amount $unit)';
  }

  /// Add time to now
  ///
  /// [amount] The positive number of units to add
  /// [unit] The time unit (year, month, week, day, hour, minute, second)
  ///
  /// Example:
  /// ```dart
  /// Now.add(1, 'day')    // "$NOW(+1 day)"
  /// Now.add(2, 'weeks')  // "$NOW(+2 weeks)"
  /// Now.add(6, 'months') // "$NOW(+6 months)"
  /// ```
  static String add(int amount, String unit) {
    return '\$NOW(+$amount $unit)';
  }

  // ========================================
  // Convenience methods for common operations
  // ========================================

  /// X seconds ago
  ///
  /// Example:
  /// ```dart
  /// Now.secondsAgo(30)  // "$NOW(-30 seconds)"
  /// ```
  static String secondsAgo(int seconds) =>
      '\$NOW(-$seconds ${seconds == 1 ? 'second' : 'seconds'})';

  /// X seconds from now
  ///
  /// Example:
  /// ```dart
  /// Now.secondsFromNow(30)  // "$NOW(+30 seconds)"
  /// ```
  static String secondsFromNow(int seconds) =>
      '\$NOW(+$seconds ${seconds == 1 ? 'second' : 'seconds'})';

  /// X minutes ago
  ///
  /// Example:
  /// ```dart
  /// Now.minutesAgo(15)  // "$NOW(-15 minutes)"
  /// ```
  static String minutesAgo(int minutes) =>
      '\$NOW(-$minutes ${minutes == 1 ? 'minute' : 'minutes'})';

  /// X minutes from now
  ///
  /// Example:
  /// ```dart
  /// Now.minutesFromNow(30)  // "$NOW(+30 minutes)"
  /// ```
  static String minutesFromNow(int minutes) =>
      '\$NOW(+$minutes ${minutes == 1 ? 'minute' : 'minutes'})';

  /// X hours ago
  ///
  /// Example:
  /// ```dart
  /// Now.hoursAgo(24)  // "$NOW(-24 hours)"
  /// ```
  static String hoursAgo(int hours) =>
      '\$NOW(-$hours ${hours == 1 ? 'hour' : 'hours'})';

  /// X hours from now
  ///
  /// Example:
  /// ```dart
  /// Now.hoursFromNow(48)  // "$NOW(+48 hours)"
  /// ```
  static String hoursFromNow(int hours) =>
      '\$NOW(+$hours ${hours == 1 ? 'hour' : 'hours'})';

  /// X days ago
  ///
  /// Example:
  /// ```dart
  /// Now.daysAgo(7)  // "$NOW(-7 days)"
  /// ```
  static String daysAgo(int days) =>
      '\$NOW(-$days ${days == 1 ? 'day' : 'days'})';

  /// X days from now
  ///
  /// Example:
  /// ```dart
  /// Now.daysFromNow(30)  // "$NOW(+30 days)"
  /// ```
  static String daysFromNow(int days) =>
      '\$NOW(+$days ${days == 1 ? 'day' : 'days'})';

  /// X weeks ago
  ///
  /// Example:
  /// ```dart
  /// Now.weeksAgo(2)  // "$NOW(-2 weeks)"
  /// ```
  static String weeksAgo(int weeks) =>
      '\$NOW(-$weeks ${weeks == 1 ? 'week' : 'weeks'})';

  /// X weeks from now
  ///
  /// Example:
  /// ```dart
  /// Now.weeksFromNow(4)  // "$NOW(+4 weeks)"
  /// ```
  static String weeksFromNow(int weeks) =>
      '\$NOW(+$weeks ${weeks == 1 ? 'week' : 'weeks'})';

  /// X months ago
  ///
  /// Example:
  /// ```dart
  /// Now.monthsAgo(3)  // "$NOW(-3 months)"
  /// ```
  static String monthsAgo(int months) =>
      '\$NOW(-$months ${months == 1 ? 'month' : 'months'})';

  /// X months from now
  ///
  /// Example:
  /// ```dart
  /// Now.monthsFromNow(6)  // "$NOW(+6 months)"
  /// ```
  static String monthsFromNow(int months) =>
      '\$NOW(+$months ${months == 1 ? 'month' : 'months'})';

  /// X years ago
  ///
  /// Example:
  /// ```dart
  /// Now.yearsAgo(1)  // "$NOW(-1 year)"
  /// ```
  static String yearsAgo(int years) =>
      '\$NOW(-$years ${years == 1 ? 'year' : 'years'})';

  /// X years from now
  ///
  /// Example:
  /// ```dart
  /// Now.yearsFromNow(5)  // "$NOW(+5 years)"
  /// ```
  static String yearsFromNow(int years) =>
      '\$NOW(+$years ${years == 1 ? 'year' : 'years'})';

  // ========================================
  // Named constants for common use cases
  // ========================================

  /// Yesterday (1 day ago)
  static String get yesterday => daysAgo(1);

  /// Tomorrow (1 day from now)
  static String get tomorrow => daysFromNow(1);

  /// Last week (7 days ago)
  static String get lastWeek => weeksAgo(1);

  /// Next week (7 days from now)
  static String get nextWeek => weeksFromNow(1);

  /// Last month (1 month ago)
  static String get lastMonth => monthsAgo(1);

  /// Next month (1 month from now)
  static String get nextMonth => monthsFromNow(1);

  /// Last year (1 year ago)
  static String get lastYear => yearsAgo(1);

  /// Next year (1 year from now)
  static String get nextYear => yearsFromNow(1);

  /// Start of today (midnight) - Note: Directus doesn't support this natively
  /// Use daysAgo(0) as approximation or handle in application logic
  static String get startOfToday => value;

  static String get midNight =>
      '${DateTime.now().toIso8601String().split('T').first}T00:00:00Z';

  /// One hour ago
  static String get oneHourAgo => hoursAgo(1);

  /// One hour from now
  static String get oneHourFromNow => hoursFromNow(1);
}
