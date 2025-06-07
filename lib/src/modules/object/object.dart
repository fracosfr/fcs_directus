import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/modules/item/item.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModObject {
  ModObject(this._requestManager);

  final RequestManager _requestManager;

  /// Get an Item Object (child of [DirectusItemModel] with identifier as [id])
  /// Return an [T extends DirectusItemModel] object build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<T?> getById<T extends DirectusItemModel>({
    required String id,
    required T Function(Map<String, dynamic> data) itemCreator,
    Duration? cache,
  }) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    final res = await modItem.readMany(
      cache: cache ?? test.cache,
      params: DirectusParams(
        filter: Filter.equal("id", id),
        fields: [test.cascadeFilter],
      ),
    );
    if (res.isNotEmpty) return itemCreator(res.first);
    return null;
  }

  /// Get an Item Object (child of [DirectusItemModel] with filter )
  /// Return an [T extends DirectusItemModel] object build with [itemCreator] (use the [DirectusItemModel.creator])
  Future<T?> getOne<T extends DirectusItemModel>(
      {DirectusParams? params,
      required T Function(Map<String, dynamic> data) itemCreator,
      Duration? cache}) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    params ??= DirectusParams();
    params.fields ??= [test.cascadeFilter];

    final res = await modItem.readMany(
      params: params,
      cache: test.disableCache ? null : cache ?? test.cache,
    );
    return itemCreator(res.first);
  }

  /// Get an array of Item Object (child of [DirectusItemModel])
  /// Return an [List<T extends DirectusItemModel>] object list build with [itemCreator] (use the [DirectusItemModel.creator]).
  /// If the [jsonData] param is != null, the request will be based on the [jsonData] value and no http request will be send.
  Future<List<T>> getMany<T extends DirectusItemModel>(
      {required T Function(Map<String, dynamic> data) itemCreator,
      DirectusParams? params,
      String? jsonData,
      Duration? cache}) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    params ??= DirectusParams();
    params.fields ??= [test.cascadeFilter];

    final res = await modItem.readMany(
      params: params,
      cache: test.disableCache ? null : cache ?? test.cache,
      jsonData: jsonData,
    );

    List<T> resultList = [];
    for (final r in res) {
      resultList.add(itemCreator(r));
    }

    return resultList;
  }

  /// Get an json object from the request [getMany].
  Future<String> getManyJson<T extends DirectusItemModel>({
    required T Function(Map<String, dynamic> data) itemCreator,
    DirectusParams? params,
  }) async {
    // Get item test information with itemCreator
    final test = _getObjTest(itemCreator);

    // Get data
    final modItem = ModItem(_requestManager, test.name);

    params ??= DirectusParams();
    params.fields ??= [test.cascadeFilter];

    final res = await modItem.readManyJson(
      params: params,
    );

    return res;
  }

  /// Create an item on Directus with [object] data.
  /// Return the [T] object item created
  Future<T?> createOne<T extends DirectusItemModel>(T object) async {
    final objInfo = _getObjTest((data) {
      return object;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    object.rebuild(await modItem.createOne(object.toMap(onlyChanges: false)));

    return object;
  }

  /// Create or update an <T>[object], if an identifier is present in object
  /// the update method was called otherwise, the creation method will be
  /// called.
  Future<T?> saveOne<T extends DirectusItemModel>(T object) =>
      object.identifier.isEmpty ? createOne(object) : updateOne(object);

  /// Create many [T] objects in Directus, return a [List<T>] with the created objects
  Future<List<T>> createMany<T extends DirectusItemModel>({
    required List<T> objects,
    required T Function(Map<String, dynamic> data) itemCreator,
  }) async {
    if (objects.isEmpty) return [];

    final List<Map<String, dynamic>> mapList = [];
    for (final obj in objects) {
      mapList.add(obj.toMap(onlyChanges: false));
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

  /// Update one [T] item in Directus serveur (only values changes if [T] is builds by directus request)
  Future<T?> updateOne<T extends DirectusItemModel>(T object) async {
    final objInfo = _getObjTest((data) {
      return object;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    object.rebuild(await modItem.updateOne(object.identifier, object.toMap()));

    return object;
  }

  /// Update many [T] objects with the data of the [sourceObject]
  Future<List<T>> updateMany<T extends DirectusItemModel>({
    required List<T> objects,
    required T Function(Map<String, dynamic> data) itemCreator,
    required T sourceObject,
  }) async {
    if (objects.isEmpty) return [];

    final List<String> ids = [];
    for (final obj in objects) {
      ids.add(obj.identifier);
    }

    final objInfo = _getObjTest((data) {
      return objects.first;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    final resultItems = await modItem.updateMany(ids, sourceObject.toMap());

    final List<T> result = [];
    for (final item in resultItems) {
      result.add(itemCreator(item));
    }

    return result;
  }

  /// Delete the [T] object in Directus
  Future<bool> deleteOne<T extends DirectusItemModel>(T object) async {
    final objInfo = _getObjTest((data) {
      return object;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    return await modItem.deleteOne(object.identifier);
  }

  /// Delete the [T] objects present in the [objects] list.
  Future<bool> deleteMany<T extends DirectusItemModel>(List<T> objects) async {
    if (objects.isEmpty) return false;

    final List<String> ids = [];
    for (final obj in objects) {
      ids.add(obj.identifier);
    }

    final objInfo = _getObjTest((data) {
      return objects.first;
    });

    final modItem = ModItem(_requestManager, objInfo.name);
    return await modItem.deleteMany(ids);
  }

  _ObjTestInfo _getObjTest<T extends DirectusItemModel>(
      T Function(Map<String, dynamic> data) itemCreator) {
    final obj = itemCreator({});
    String itemName = obj.itemName ?? "";
    if (itemName.isEmpty) itemName = _getItemNameFromClassName(T.toString());
    return _ObjTestInfo(
      name: itemName,
      cascadeLevel: obj.cascadeLevel,
      cache: obj.cache,
      disableCache: obj.disableCache,
    );
  }

  String _getItemNameFromClassName(String className) {
    if (!className.endsWith("Object") && !className.endsWith("Obj")) {
      throw DirectusErrorObjectClassName(className);
    }

    final tmpName = className.substring(
        0, className.length - (className.endsWith("Object") ? 6 : 3));
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
  final Duration? cache;
  late String cascadeFilter;
  final bool disableCache;

  _ObjTestInfo({
    required this.name,
    this.cascadeLevel = 0,
    this.cache,
    required this.disableCache,
  }) {
    String fields = "*";
    for (int l = 0; l < cascadeLevel; l++) {
      fields += ".*";
    }
    cascadeFilter = fields;
  }
}
