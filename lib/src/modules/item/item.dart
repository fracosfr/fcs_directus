import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/modules/item/generic_item_model.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

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
      final model = GenericItemModel.creator(response);
      return model.items.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> readMany({DirectusParams? params}) async {
    if (params == null) {
      final response = await _requestManager.executeRequest(
        url: "/items/$_itemName",
      );
      ErrorParser(response).sendError();

      try {
        final model = GenericItemModel.creator(response);
        return model.items;
      } catch (e) {
        rethrow;
      }
    } else {
      final response = await _requestManager.executeRequest(
        url: params.generateUrl("/items/$_itemName"),
      );

      ErrorParser(response).sendError();

      try {
        final model = GenericItemModel.creator(response);
        return model.items;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> createOne(Map<String, dynamic> itemData) async {
    final response = await _requestManager.executeRequest(
      url: "/items/$_itemName",
      method: HttpMethod.post,
      data: itemData,
    );
    ErrorParser(response).sendError();

    try {
      final model = GenericItemModel.creator(response);
      return model.items.first;
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
      final model = GenericItemModel.creator(response);
      return model.items;
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
      final model = GenericItemModel.creator(response);
      return model.items.first;
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
      final model = GenericItemModel.creator(response);
      return model.items;
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
      final model = GenericItemModel.creator(response);
      return model.items;
    } catch (e) {
      rethrow;
    }
  }
}
