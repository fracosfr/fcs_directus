enum DirectusAggregateType {
  /// Counts how many items there are
  count,

  /// Counts how many unique items there are
  countDistinct,

  /// Adds together the values in the given field
  sum,

  /// Adds together the unique values in the given field
  sumDistinct,

  /// Get the average value of the given field
  avg,

  /// Get the average value of the unique values in the given field
  avgDistinct,

  ///	Return the lowest value in the field
  min,

  ///	Return the highest value in the field
  max,
}

extension DirectusAggregateTypeExtension on DirectusAggregateType {
  String get value {
    return toString().split('.').last;
  }
}
