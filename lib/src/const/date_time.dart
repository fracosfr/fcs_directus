class DirectusDateTime {
  /// Extract the year from a datetime/date/timestamp field
  static String year(String field) => "year($field)";

  /// Extract the month from a datetime/date/timestamp field
  static String month(String field) => "month($field)";

  /// Extract the week from a datetime/date/timestamp field
  static String week(String field) => "week($field)";

  /// Extract the day from a datetime/date/timestamp field
  static String day(String field) => "day($field)";

  /// Extract the weekday from a datetime/date/timestamp field
  static String weekday(String field) => "weekday($field)";

  /// Extract the hour from a datetime/date/timestamp field
  static String hour(String field) => "hour($field)";

  /// Extract the minute from a datetime/date/timestamp field
  static String minute(String field) => "minute($field)";

  /// Extract the second from a datetime/date/timestamp field
  static String second(String field) => "second($field)";
}
