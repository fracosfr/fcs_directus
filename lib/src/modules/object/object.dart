import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/errors/errors.dart';
import 'package:fcs_directus/src/modules/item/item.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModObject {
  ModObject(this._requestManager);

  final RequestManager _requestManager;

  /// Get an Item Object (child of [DirectusItemModel] with identifier as [id])
  /// Return an [T extends DirectusItemModel] object build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<T?> getById<T extends DirectusItemModel>({
    required String id,
    required T Function(dynamic data) itemCreator,
  }) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    final res = await modItem.readMany(
        params: DirectusParams(filter: {
      "id": {"_eq": id}
    }, fields: [
      test.cascadeFilter
    ]));
    return itemCreator(res.first);
  }

  /// Get an Item Object (child of [DirectusItemModel] with filter )
  /// Return an [T extends DirectusItemModel] object build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<T?> getOne<T extends DirectusItemModel>({
    DirectusParams? params,
    required T Function(dynamic data) itemCreator,
  }) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    params ??= DirectusParams();
    params.fields ??= [test.cascadeFilter];

    final res = await modItem.readMany(params: params);
    return itemCreator(res.first);
  }

  /// Get an array of Item Object (child of [DirectusItemModel])
  /// Return an [List<T extends DirectusItemModel>] object list build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<List<T>> getMany<T extends DirectusItemModel>({
    required T Function(dynamic data) itemCreator,
    DirectusParams? params,
  }) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    params ??= DirectusParams();
    params.fields ??= [test.cascadeFilter];

    final res = await modItem.readMany(
      params: params,
    );

    List<T> resultList = [];
    for (final r in res) {
      resultList.add(itemCreator(r));
    }

    return resultList;
  }

  /// Create an item on Directus with [object] data.
  /// Return the [T] object item created
  Future<T> createOne<T extends DirectusItemModel>(T object) async {
    final objInfo = _getObjTest((data) {
      return object;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    object.rebuild(await modItem.createOne(object.toMap()));

    return object;
  }

  Future<List<T>> createMany<T extends DirectusItemModel>({
    required List<T> objects,
    required T Function(dynamic data) itemCreator,
  }) async {
    if (objects.isEmpty) return [];

    final List<Map<String, dynamic>> mapList = [];
    for (final obj in objects) {
      mapList.add(obj.toMap());
    }

    final objInfo = _getObjTest((data) {
      return objects.first;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    final resultItems = await modItem.createMany(mapList);

    final List<T> result = [];
    for (final item in resultItems) {
      result.add(itemCreator(item));
    }

    return result;
  }

  _ObjTestInfo _getObjTest<T extends DirectusItemModel>(
      T Function(dynamic data) itemCreator) {
    final obj = itemCreator(null);
    String itemName = obj.itemName ?? "";
    if (itemName.isEmpty) itemName = _getItemNameFromClassName(T.toString());
    return _ObjTestInfo(name: itemName, cascadeLevel: obj.cascadeLevel);
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

class _ObjTestInfo {
  final String name;
  final int cascadeLevel;

  late String cascadeFilter;

  _ObjTestInfo({required this.name, this.cascadeLevel = 0}) {
    String fields = "*";
    for (int l = 0; l < cascadeLevel; l++) {
      fields += ".*";
    }
    cascadeFilter = fields;
  }
}
