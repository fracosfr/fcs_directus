import 'package:fcs_directus/fcs_directus.dart';

class BrandObject extends DirectusItemModel {
  BrandObject.creator(super.data) : super.creator();

  String get name => getValue("name") ?? "";
}
