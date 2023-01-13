import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/errors/errors.dart';
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

  getById({required String id}) {
    print("REQUEST ITEM $id");
  }

  getOne({String? filter}) {
    print("GET ONE ITEM");
  }

  Future<List<dynamic>> getMultiples({Map<String, dynamic>? filter}) async {
    if (filter == null) {
      final response = await _requestManager.executeRequest(
        url: "/items/$_itemName",
      );
      ErrorParser(response).sendError();

      try {
        final model = GenericItemModel.fromDirectus(response);
        return model.items;
      } catch (e) {
        rethrow;
      }
    } else {
      final response = await _requestManager.executeRequest(
        url: "/items/$_itemName?filter${_parseFilterUrl(filter)}",
      );
      ErrorParser(response).sendError();

      try {
        final model = GenericItemModel.fromDirectus(response);
        return model.items;
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Advanced Search method, same as the [getMultiples] but filter can be used with multiples levels.
  /// NOTE : This method use the HTTP SEARCH method !
  /// Before using it make sure that your Directus Server allow this method.
  Future<List<dynamic>> search({required Map<String, dynamic> filter}) async {
    final response = await _requestManager.executeRequest(
      method: HttpMethod.search,
      url: "/items/$_itemName",
      data: {
        "query": {"filter": filter}
      },
    );
    ErrorParser(response).sendError();

    try {
      final model = GenericItemModel.fromDirectus(response);
      return model.items;
    } catch (e) {
      rethrow;
    }
  }

  String _parseFilterUrl(Map<String, dynamic> filter) {
    String filterUrl = "";
    dynamic filterVal = filter;
    int levelCount = 0;
    try {
      while (filterVal != null) {
        if (filterVal is Map<String, dynamic>) {
          String key = filterVal.keys.first;
          filterVal = filterVal[key];
          filterUrl += "[$key]";
        } else {
          if ([String, int, double, bool].contains(filterVal.runtimeType)) {
            filterUrl += "=$filterVal";
            filterVal = null;
          } else {
            throw DirectusErrorHttpFilterValue();
          }
        }
        levelCount++;

        if (levelCount > 10) throw DirectusErrorHttpFilterTooDeep();
      }
    } catch (_) {
      throw DirectusErrorHttpFilterInvalid();
    }

    return filterUrl;
  }
}
