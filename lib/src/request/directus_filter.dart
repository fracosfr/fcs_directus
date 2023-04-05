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
  static DirectusFilterListFilter or(List<DirectusFilterContructor> items) =>
      DirectusFilterListFilter("_or", items);
  static DirectusFilterListFilter and(List<DirectusFilterContructor> items) =>
      DirectusFilterListFilter("_and", items);

  static DirectusFilterList isOneOf(String column, List<dynamic> items) =>
      DirectusFilterList("_in", column, items);

  static DirectusFilterValue equal(String column, dynamic value) =>
      DirectusFilterValue("_eq", column, value);
  static DirectusFilterValue greaterThan(String column, dynamic value) =>
      DirectusFilterValue("_gt", column, value);

  static DirectusFilterNoValue isNull(String column) =>
      DirectusFilterNoValue("_null", column);
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

    return mapParser(column, {key: jsonEncode(obj)});
  }
}

class DirectusFilterNoValue extends DirectusFilterContructor {
  DirectusFilterNoValue(super.key, this.column);
  final String column;

  @override
  Map get map => mapParser(column, key);
}
