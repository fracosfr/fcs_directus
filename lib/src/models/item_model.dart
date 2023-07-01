import 'package:fcs_directus/src/fcs_directus_base.dart';
import 'package:meta/meta.dart';

abstract class DirectusItemModel {
  final Map<String, dynamic> _values = {};
  //final Map<String, dynamic> _rawValues = {};
  final Map<String, dynamic> _updatedValues = {};

  // A VALIDER

  /// Get the item name used to make request on Directus, override it if your class name dont respect the camel case.
  /// Use "MyClassNameObject" or "MyClassNameObj" for "my_class_name" item name in directus.
  String? get itemName => null;

  /// Get the unique identifier of the object
  String get identifier => getValue("id") ?? "";

  /// Force multiple level on request => use it if you want retrieve a sub object
  /// level 0 eq *, level 1 eq *.*, level 2 eq *.*.* etc...
  int get cascadeLevel => 0;

  DirectusItemModel();

  /// Creator constructor, used to convert the Directus responses.
  DirectusItemModel.creator(Map<String, dynamic> data) {
    rebuild(data);
  }

  void rebuild(Map<String, dynamic> data) {
    _values.clear();
    //_rawValues.clear();
    _updatedValues.clear();

    _values.addAll(data);
  }

  /// set a [value] corresponding with the [key].
  @protected
  setValue(String key, dynamic value) {
    if (key.contains(".")) {
      final keyList = key.split(".");
      Map<String, dynamic> current = {keyList.last: value};
      keyList.removeLast();
      while (keyList.isNotEmpty) {
        current = {keyList.last: current};
        keyList.removeLast();
      }

      _updatedValues.combineRecursive(current);
      return;
    }

    _updatedValues[key] = value;
  }

  /// set an [object] corresponding with the [key]
  @protected
  setObject(String key, DirectusItemModel object) =>
      setValue(key, object.toMap(onlyChanges: false));

  /// Retrieve a value correspond with the [key]
  @protected
  T? getValue<T>(String key) {
    if (key.contains(".")) {
      final keyList = key.split(".");
      Map<String, dynamic> current = toMap(onlyChanges: false);

      while (keyList.isNotEmpty) {
        if (!current.containsKey(keyList.first)) return null;

        if (keyList.length == 1) {
          return current[keyList.first] is T ? current[keyList.first] : null;
        }

        if (current[keyList.first] is Map<String, dynamic>) {
          current = current[keyList.first];
        }

        keyList.removeAt(0);
      }
    }

    final vals = toMap(onlyChanges: false);
    if (!vals.containsKey(key)) return null;

    if (T == DateTime) {
      String dateString = vals[key];
      return DateTime.tryParse(dateString) as T;
    }
    try {
      return vals[key];
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap({bool onlyChanges = true}) {
    final Map<String, dynamic> res = {};

    if (!onlyChanges) res.combineRecursive(_values);
    res.combineRecursive(_updatedValues);

    return res;
  }

  List<T> getObjectList<T>(
      String key, T Function(Map<String, dynamic> data) itemCreator) {
    final List<T> result = [];
    List<dynamic> data = getValue(key);

    for (final item in data) {
      result.add(itemCreator(item));
    }

    return result;
  }

  /// Retrieve an object correspond with the [key]
  @protected
  T getObject<T extends DirectusItemModel>(
    String key,
    T Function(Map<String, dynamic> data) creator,
  ) {
    return creator(getValue<Map<String, dynamic>>(key) ?? <String, dynamic>{});
  }

  save({FcsDirectus? directusInstance}) async {
    directusInstance ??= FcsDirectus.instance;
    final res = identifier.isEmpty
        ? await directusInstance.object.createOne(this)
        : await directusInstance.object.updateOne(this);

    rebuild(res.toMap(onlyChanges: false));
  }
}

extension MapCombineRecursive on Map<String, dynamic> {
  combineRecursive(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      if (containsKey(entry.key)) {
        if (entry.value is Map<String, dynamic>) {
          if (this[entry.key] is! Map<String, dynamic>) this[entry.key] = {};
          Map<String, dynamic> tmp = this[entry.key];
          tmp.combineRecursive(entry.value);
          this[entry.key] = tmp;
        } else {
          this[entry.key] = entry.value;
        }
      } else {
        this[entry.key] = entry.value;
      }
    }
  }
}
