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
  Map get map;
  String get json => jsonEncode(map);

  @override
  String toString() => json;

  dynamic parseData(dynamic data) {
    if (data.runtimeType == DateTime) return data.toString();
    return data;
  }
}

class Filter extends DirectusFilterContructor {
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
}

class FilterAnd extends DirectusFilterContructor {
  FilterAnd(this.items);
  final List<DirectusFilterContructor> items;

  @override
  Map get map {
    List<Map> obj = [];

    for (final i in items) {
      obj.add(i.map);
    }

    return {"_and": obj};
  }
}

class FilterOr extends DirectusFilterContructor {
  FilterOr(this.items);
  final List<DirectusFilterContructor> items;

  @override
  Map get map {
    List<Map> obj = [];

    for (final i in items) {
      obj.add(i.map);
    }

    return {"_or": obj};
  }
}

class FilterIsOneOf extends DirectusFilterContructor {
  FilterIsOneOf(this.column, this.items);
  final String column;
  final List<dynamic> items;

  @override
  Map get map {
    List<dynamic> obj = [];

    for (final i in items) {
      obj.add(parseData(i));
    }

    return {
      column: {"_in": obj.toString()}
    };
  }
}

class FilterIsNotOneOf extends DirectusFilterContructor {
  FilterIsNotOneOf(this.column, this.items);
  final String column;
  final List<dynamic> items;

  @override
  Map get map {
    List<dynamic> obj = [];

    for (final i in items) {
      obj.add(parseData(i));
    }

    return {
      column: {"_nin": obj.toString()}
    };
  }
}

class FilterIsNull extends DirectusFilterContructor {
  FilterIsNull(this.column);
  final String column;

  @override
  Map get map => {column: "_null"};
}
