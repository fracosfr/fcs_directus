import 'package:fcs_directus/src/models/item_model.dart';

class DirectusServerHealthStatusModel extends DirectusItemModel {
  DirectusServerHealthStatusModel.fromDirectus(super.data) : super.creator();

  @override
  String? get itemName => null;

  String get status => getValue("status") ?? "";
  String get componentType => getValue("componentType") ?? "";
  String? get observedUnit => getValue("observedUnit");
  double? get observedValue => getValue("observedValue");
}
