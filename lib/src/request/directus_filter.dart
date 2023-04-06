import 'dart:convert';

abstract class DirectusFilterContructor {
  DirectusFilterContructor(this.key);
  final String key;
  Map get map;
  String get json => jsonEncode(map);

  @override
  String toString() => json;

  dynamic parseData(dynamic value) {
    if (value.runtimeType == DateTime) return value.toString();
    return value;
  }

  Map mapParser(String column, dynamic value) {
    if (column.contains(".")) {
      final cols = column.split(".");
      Map finalData = {};
      for (final String col in cols.reversed) {
        if (finalData.isEmpty) {
          finalData = {col: value};
        } else {
          finalData = {col: finalData};
        }
      }
      return finalData;
    }

    return {column: value};
  }
}

class Filter {
  static String currentUser = "\$CURRENT_USER";
  static String currentRole = "\$CURRENT_ROLE";
  //static String now = "\$NOW";

  /// Adjustement example : [now("+2 hours")] [now("-1 year")]
  static String now({String adjustement = ""}) {
    if (adjustement.isEmpty) return "\$NOW";
    return "\$NOW($adjustement)";
  }

  static DirectusFilterListFilter or(List<DirectusFilterContructor> items) =>
      DirectusFilterListFilter("_or", items);
  static DirectusFilterListFilter and(List<DirectusFilterContructor> items) =>
      DirectusFilterListFilter("_and", items);

  static DirectusFilterList isOneOf(String column, List<dynamic> items) =>
      DirectusFilterList("_in", column, items);
  static DirectusFilterList isNotOneOf(String column, List<dynamic> items) =>
      DirectusFilterList("_nin", column, items);

  static DirectusFilterCompare between(
          String column, dynamic begin, dynamic end) =>
      DirectusFilterCompare("_between", column, begin, end);
  static DirectusFilterCompare notBetween(
          String column, dynamic begin, dynamic end) =>
      DirectusFilterCompare("_nbetween", column, begin, end);

  static DirectusFilterValue equal(String column, dynamic value) =>
      DirectusFilterValue("_eq", column, value);
  static DirectusFilterValue doesntEqual(String column, dynamic value) =>
      DirectusFilterValue("_neq", column, value);
  static DirectusFilterValue lessThan(String column, dynamic value) =>
      DirectusFilterValue("_lt", column, value);
  static DirectusFilterValue lessThanOrEqual(String column, dynamic value) =>
      DirectusFilterValue("_lte", column, value);
  static DirectusFilterValue greaterThan(String column, dynamic value) =>
      DirectusFilterValue("_gt", column, value);
  static DirectusFilterValue greaterThanOrEqual(String column, dynamic value) =>
      DirectusFilterValue("_gte", column, value);
  static DirectusFilterValue contains(String column, dynamic value) =>
      DirectusFilterValue("_contains", column, value);
  static DirectusFilterValue notContains(String column, dynamic value) =>
      DirectusFilterValue("_ncontains", column, value);
  static DirectusFilterValue startWith(String column, dynamic value) =>
      DirectusFilterValue("_starts_with", column, value);
  static DirectusFilterValue dontStartWith(String column, dynamic value) =>
      DirectusFilterValue("_nstarts_with", column, value);
  static DirectusFilterValue endsWith(String column, dynamic value) =>
      DirectusFilterValue("_ends_with", column, value);
  static DirectusFilterValue dontEndsWith(String column, dynamic value) =>
      DirectusFilterValue("_nends_with", column, value);

  static DirectusFilterNoValue isNull(String column) =>
      DirectusFilterNoValue("_null", column);
  static DirectusFilterNoValue isNotNull(String column) =>
      DirectusFilterNoValue("_nnull", column);
  static DirectusFilterNoValue isEmpty(String column) =>
      DirectusFilterNoValue("_empty", column);
  static DirectusFilterNoValue isNotEmpty(String column) =>
      DirectusFilterNoValue("_nempty", column);
}

class DirectusFilterListFilter extends DirectusFilterContructor {
  DirectusFilterListFilter(super.key, this.items);
  final List<DirectusFilterContructor> items;

  @override
  Map get map {
    List<Map> obj = [];

    for (final i in items) {
      obj.add(i.map);
    }

    return {key: obj};
  }
}

class DirectusFilterValue extends DirectusFilterContructor {
  DirectusFilterValue(super.key, this.column, this.value);
  final String column;
  final dynamic value;

  @override
  Map get map => mapParser(column, {key: parseData(value)});
}

class DirectusFilterList extends DirectusFilterContructor {
  DirectusFilterList(super.key, this.column, this.items);
  final String column;
  final List<dynamic> items;

  @override
  Map get map {
    List<dynamic> obj = [];

    for (final i in items) {
      obj.add(parseData(i));
    }

    return mapParser(column, {key: obj});
  }
}

class DirectusFilterCompare extends DirectusFilterContructor {
  DirectusFilterCompare(super.key, this.column, this.value1, this.value2);
  final String column;
  final dynamic value1;
  final dynamic value2;

  @override
  Map get map => mapParser(column, {
        key: [parseData(value1), parseData(value2)]
      });
}

class DirectusFilterNoValue extends DirectusFilterContructor {
  DirectusFilterNoValue(super.key, this.column);
  final String column;

  @override
  Map get map => mapParser(column, key);
}
