import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/directus_response.dart';
import 'package:fcs_directus/src/request/request_manager.dart';
import 'package:http/http.dart';

class ModItem {
  final RequestManager _requestManager;
  final String _itemName;

  String get name => _itemName;

  ModItem(
    this._requestManager,
    this._itemName,
  );

  Future<Map<String, dynamic>> readOne(String id) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName/$id",
    );

    ErrorParser(response).sendError();
    try {
      return response.toMap();
    } catch (e) {
      rethrow;
    }
  }

  /// Read many items in Directus
  /// If the [jsonData] param is != null, the request will be based on the [jsonData] value and no http request will be send.
  Future<List<dynamic>> readMany(
      {DirectusParams? params, String? jsonData}) async {
    if (jsonData != null) {
      final response = DirectusResponse.fromJson(jsonData);
      ErrorParser(response).sendError();
      try {
        return response.toList();
      } catch (e) {
        rethrow;
      }
    }

    String url = "/items/$_itemName";
    if (params != null) url = params.generateUrl(url);

    final response = await _requestManager.executeRequest(
      url: url,
    );
    ErrorParser(response).sendError();

    try {
      return response.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Eq [readMany] but return an json object can be stored and reuse later.
  Future<String> readManyJson({DirectusParams? params}) async {
    String url = "/items/$_itemName";
    if (params != null) url = params.generateUrl(url);

    final response = await _requestManager.executeRequest(
      url: url,
    );
    ErrorParser(response).sendError();

    return response.toJson();
  }

  Future<Map<String, dynamic>> createOne(Map<String, dynamic> itemData) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName",
      method: HttpMethod.post,
      data: itemData,
    );
    ErrorParser(response).sendError();

    try {
      return response.toMap();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> createMany(List<Map<String, dynamic>> itemsData) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName",
      method: HttpMethod.post,
      data: itemsData,
    );
    ErrorParser(response).sendError();

    try {
      return response.toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOne(
      String id, Map<String, dynamic> itemData) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName/$id",
      method: HttpMethod.patch,
      data: itemData,
    );
    ErrorParser(response).sendError();

    try {
      return response.toMap();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> updateMany(
      List<String> ids, Map<String, dynamic> itemData) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName",
      method: HttpMethod.patch,
      data: {"keys": ids, "data": itemData},
    );
    ErrorParser(response).sendError();

    try {
      return response.toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteOne(String id) async {
    final request = await _requestManager.executeRequest(
      url: "/items/$_itemName/$id",
      method: HttpMethod.delete,
      parseJson: false,
    );

    return request.rawData.isEmpty;
  }

  Future<bool> deleteMany(List<String> ids) async {
    final request = await _requestManager.executeRequest(
      url: "/items/$_itemName",
      method: HttpMethod.delete,
      data: ids,
      parseJson: false,
    );

    return request.rawData.isEmpty;
  }

  /// Advanced Search method, same as the [readMany] but filter can be used with multiples levels.
  /// NOTE : This method use the HTTP SEARCH method !
  /// Before using it make sure that your Directus Server allow this method.
  Future<List<dynamic>> readManyAdvancedFilter(
      {required Map<String, dynamic> filter}) async {
    final response = await _requestManager.executeRequest(
      method: HttpMethod.search,
      url: "/items/$_itemName",
      data: {
        "query": {"filter": filter}
      },
    );
    ErrorParser(response).sendError();

    try {
      return response.toList();
    } catch (e) {
      rethrow;
    }
  }
}
