import 'package:fcs_directus/src/models/item_model.dart';

class DirectusUserAccess extends DirectusItemModel {
  DirectusUserAccess.creator(super.data) : super.creator();

  @override
  String? get itemName => "directus_access";

  String? get role => getValue("role");
  String? get user => getValue("user");
  String? get policy => getValue("policy");
}
