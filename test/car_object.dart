import 'package:fcs_directus/fcs_directus.dart';

import 'brand_object.dart';

class CarObject extends DirectusItemModel {
  CarObject({required String name, required int doors, String? brandId}) {
    this.name = name;
    this.doors = doors;
    if (brandId != null) setValue("brand.id", brandId);
  }
  CarObject.creator(super.data) : super.creator();
  CarObject.empty();

  //@override
  //String? get itemName => "car";

  @override
  int get cascadeLevel => 1;

  String get name => getValue("name") ?? "";
  set name(String v) => setValue("name", v);

  String get engine => getValue("engine") ?? "";
  set engine(String v) => setValue("engine", v);

  int get doors => getValue("door") ?? 0;
  set doors(int v) => setValue("door", v);

  String get brandId => getValue("brand.id") ?? "";
  BrandObject get brandObject =>
      getObject("brand", (data) => BrandObject.creator(data));
  set brandObject(BrandObject o) =>
      setValue("brand", o.toMap(onlyChanges: false));
}
