import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/request/directus_response.dart';

abstract class DirectusItemModel {
  final Map<String, dynamic> _values = {};
  List<dynamic> _listValues = [];

  DirectusItemModel.fromDirectus(dynamic data) {
    dynamic finalData = data;

    if (data is DirectusResponse) {
      ErrorParser(data.data).sendError();

      if (data.data.keys.contains("data")) {
        // OK DirectusResponse contain data
        finalData = data.data["data"];
      }
    }
    if (finalData is Map<String, dynamic>) {
      // Map data
      for (final key in finalData.keys) {
        setValue(key, finalData[key]);
      }
      _listValues = [finalData];
    } else if (finalData is List<dynamic>) {
      _listValues = finalData;
    } else {
      // UnknowType
      print("ItemModel got type : ${finalData.runtimeType}");
    }
  }

  List<dynamic> get items => _listValues;

  setValue(String key, dynamic value) {
    _values[key] = value;
  }

  T? getValue<T>(String key) {
    final v = _values[key];
    if (v.runtimeType == T) return v;
    return null;
  }
}
