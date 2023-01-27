import 'package:fcs_directus/fcs_directus.dart';

class BrandObject extends DirectusItemModel {
  BrandObject(String name) {
    this.name = name;
  }
  BrandObject.creator(super.data) : super.creator();

  String get name => getValue("name") ?? "";
  set name(String v) => setValue("name", v);
}
