import 'package:fcs_directus/src/models/item_model.dart';

class GenericItemModel extends DirectusItemModel {
  GenericItemModel.fromDirectus(super.data) : super.creator();
}
