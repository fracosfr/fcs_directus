import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/modules/item/item.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModObject {
  ModObject(this._requestManager);

  final RequestManager _requestManager;

  /// Get an Item Object (child of [DirectusItemModel] with identifier as [id])
  /// Return an [T extends DirectusItemModel] object build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<T> getOne<T extends DirectusItemModel>({
    required String id,
    required T Function(dynamic data) itemCreator,
  }) async {
    // Get item name
    final test = itemCreator(null);
    String itemName = test.itemName ?? "";
    final int cascadeLevel = test.cascadeLevel;
    if (itemName.isEmpty) itemName = _getItemNameFromClassName(T.toString());

    // Get data
    final modItem = ModItem(_requestManager, itemName);
    String fields = "*";
    for (int l = 0; l < cascadeLevel; l++) {
      fields += ".*";
    }
    final res = await modItem.readMany(
        params: DirectusParams(filter: {
      "id": {"_eq": id}
    }, fields: [
      fields
    ]));
    return itemCreator(res.first);
  }

  Future<List<T>> getMany<T extends DirectusItemModel>({
    required T Function(dynamic data) itemCreator,
  }) async {
    return [];
  }

  String _getItemNameFromClassName(String className) {
    if (!className.endsWith("Object")) {
      throw DirectusErrorObjectClassName(className);
    }

    final tmpName = className.substring(0, className.length - 6);
    String name = tmpName[0].toLowerCase();
    final majKey = "AZERTYUIOPMLKJHGFDSQWXCVBN";
    for (int i = 1; i < tmpName.length; i++) {
      if (majKey.contains(tmpName[i])) name += "_";
      name += tmpName[i].toLowerCase();
    }
    return name;
  }
}
