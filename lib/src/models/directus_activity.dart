import 'package:fcs_directus/src/models/item_model.dart';

class DirectusActivityColums {
  final String action = "action";
  final String collection = "collection";
  final String comment = "comment";
  final String id = "id";
  final String ip = "ip";
  final String item = "item";
  final String timestamp = "timestamp";
  final String user = "user";
  final String userAgent = "user_agent";
  final String revisions = "revisions";
}

class DirectusActivity extends DirectusItemModel {
  DirectusActivity.creator(super.data) : super.creator();

  @override
  String? get itemName => "activity";

  static DirectusActivityColums get cols => DirectusActivityColums();

  String get action => getValue(cols.action) ?? "";
  String get collection => getValue(cols.collection) ?? "";
  String get comment => getValue(cols.comment) ?? "";
  String get id => getValue(cols.id) ?? "";
  String get ip => getValue(cols.ip) ?? "";
  String get item => getValue(cols.item) ?? "";
  DateTime get timestamp => getValue(cols.timestamp) ?? DateTime(1900);
  String get user => getValue(cols.user) ?? "";
  String get userAgent => getValue(cols.userAgent) ?? "";
  String get revisions => getValue(cols.revisions) ?? "";
}
