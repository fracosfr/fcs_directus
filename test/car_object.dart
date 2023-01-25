import 'package:fcs_directus/fcs_directus.dart';

import 'brand_object.dart';

class CarObject extends DirectusItemModel {
  CarObject.creator(super.data) : super.creator();

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
}
