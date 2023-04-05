import 'dart:convert';

enum FilterKey {
  equal,
  doesntEqual,
  lessThan,
  lessThanOrEqualTo,
  greaterThan,
  greaterThanOrEqualTo,
  isntNull,
  contains,
  coesntContain,
  startsWith,
  doesntStartWith,
  endsWith,
  doesntEndWith,
  isBetween,
  isntBetween,
  isEmpty,
  isntEmpty,
  intersects,
  doesntIntersect,
  intersectsBoundingBox,
  doesntIntersectBoundingBox,
  currentUser,
  currentRole,
  now,
}

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

/*class Filter extends DirectusFilterContructor {
  Filter(this.column, this.key, this.value);
  final FilterKey key;
  final dynamic value;
  final String column;

  Map get map => {
        column: {filterToString(key): parseData(value)}
      };

  static String filterToString(FilterKey key) {
    switch (key) {
      case FilterKey.equal:
        return "_eq";
      case FilterKey.doesntEqual:
        return "_neq";
      case FilterKey.lessThan:
        return "_lt";
      case FilterKey.lessThanOrEqualTo:
        return "_lte";
      case FilterKey.greaterThan:
        return "_gt";
      case FilterKey.greaterThanOrEqualTo:
        return "_gte";
      case FilterKey.isntNull:
        return "_nnuul";
      case FilterKey.contains:
        return "_contains";
      case FilterKey.coesntContain:
        return "_ncontains";
      case FilterKey.startsWith:
        return "_starts_with";
      case FilterKey.doesntStartWith:
        return "_nstarts_with";
      case FilterKey.endsWith:
        return "_ends_with";
      case FilterKey.doesntEndWith:
        return "_nends_with";
      case FilterKey.isBetween:
        return "_between";
      case FilterKey.isntBetween:
        return "_nbetween";
      case FilterKey.isEmpty:
        return "_empty";
      case FilterKey.isntEmpty:
        return "_nempty";
      case FilterKey.intersects:
        return "_intersects";
      case FilterKey.doesntIntersect:
        return "_nintersects";
      case FilterKey.intersectsBoundingBox:
        return "_intersects_bbox";
      case FilterKey.doesntIntersectBoundingBox:
        return "_nintersects_bbox";
      case FilterKey.currentUser:
        return "\$CURRENT_USER";
      case FilterKey.currentRole:
        return "\$CURRENT_ROLE";
      case FilterKey.now:
        return "\$NOW";
    }
  }
}*/

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

    return mapParser(column, {key: obj.toString()});
  }
}

class DirectusFilterNoValue extends DirectusFilterContructor {
  DirectusFilterNoValue(super.key, this.column);
  final String column;

  @override
  Map get map => mapParser(column, key);
}
