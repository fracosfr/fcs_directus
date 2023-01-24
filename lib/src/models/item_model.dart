import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/request/directus_response.dart';

abstract class DirectusItemModel {
  final Map<String, dynamic> _values = {};
  final Map<String, dynamic> _rawValues = {};
  List<dynamic> _listValues = [];

  /// Get the item name used to make request on Directus, override it if your class name dont respect the camel case.
  /// Use "MyClassNameObject" for "my_class_name" item name in directus.
  String? get itemName => null;

  /// Get the unique identifier of the object
  String get identifier => getValue("id") ?? "";

  /// Force multiple level on request => use it if you want retrieve a sub object
  /// level 0 eq *, level 1 eq *.*, level 2 eq *.*.* etc...
  int get cascadeLevel => 0;

  /// Creator constructor, used to convert the Directus responses.
  DirectusItemModel.creator(dynamic data) {
    if (data == null) return;
    dynamic finalData = data;

    if (data is DirectusResponse) {
      ErrorParser(data.data).sendError();

      if (data.data.keys.contains("data")) {
        // OK DirectusResponse contain data
        finalData = data.data["data"];
      } else {
        finalData = data.data;
      }
    }
    if (finalData is Map<String, dynamic>) {
      // Map data
      for (final key in finalData.keys) {
        _setValueFromMap(key, finalData);
        _rawValues[key] = finalData[key];
      }
      _listValues = [finalData];
    } else if (finalData is List<dynamic>) {
      _listValues = finalData;
    } else {
      // UnknowType
      print("ItemModel got type : ${finalData.runtimeType}");
    }
  }

  void _setValueFromMap(String key, dynamic data, {String finalKey = ""}) {
    if (finalKey.isNotEmpty) finalKey += ".";
    finalKey += key;

    if (data[key] is Map<String, dynamic>) {
      for (final k in data[key].keys) {
        _setValueFromMap(k, data[key], finalKey: finalKey);
      }
    } else {
      setValue(finalKey, data[key]);
    }
  }

  List<dynamic> get items => _listValues;

  setValue(String key, dynamic value) {
    _values[key] = value;
  }

  /// Retrieve an value correspond with the [key]
  T? getValue<T>(String key) {
    final v = _values[key];
    if (v.runtimeType == T) return v;
    return null;
  }

  List<T> getObjectList<T>(String key, T Function(dynamic data) itemCreator) {
    final List<T> result = [];
    List<dynamic> data = [];

    if (key.contains(".")) {
      List<String> keyItems = key.split(".");
      Map<String, dynamic> tmpData = _rawValues;
      while (keyItems.isNotEmpty) {
        if (tmpData.keys.contains(keyItems.first)) {
          print(tmpData[keyItems.first].runtimeType);
          if (tmpData[keyItems.first] is List<dynamic>) {
            data = tmpData[keyItems.first];
            keyItems.clear();
          } else if (tmpData[keyItems.first] is Map<String, dynamic>) {
            tmpData = tmpData[keyItems.first];
            keyItems.removeAt(0);
          }
        } else {
          keyItems.clear();
        }
      }
    } else {
      data = _rawValues[key] ?? [];
    }

    for (final item in data) {
      result.add(itemCreator(item));
    }

    return result;
  }

  T getObject<T>(String key, T Function(dynamic data) itemCreator) {
    Map<String, dynamic> data = {};

    if (key.contains(".")) {
      List<String> keyItems = key.split(".");
      Map<String, dynamic> tmpData = _rawValues;
      while (keyItems.isNotEmpty) {
        if (tmpData.keys.contains(keyItems.first)) {
          print(tmpData[keyItems.first].runtimeType);
          if (tmpData[keyItems.first] is Map<String, dynamic>) {
            tmpData = tmpData[keyItems.first];
            keyItems.removeAt(0);
            data = tmpData;
          }
        } else {
          keyItems.clear();
        }
      }
    } else {
      data = _rawValues[key] ?? {};
    }

    return itemCreator(data);
  }
}
