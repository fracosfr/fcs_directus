import 'package:fcs_directus/src/models/directus_user.dart';
import 'package:fcs_directus/src/models/item_model.dart';

class DirectusPolicieModelColums {
  final String name = "name";
  final String icon = "icon";
  final String description = "description";
  final String ipAccess = "ip_access";
  final String enforceFfa = "enforce_tfa";
  final String adminAccess = "admin_access";
  final String appAccess = "app_access";
  final String users = "users";
  final String roles = "roles";
  final String permissions = "permissions";
}

class DirectusPolicie extends DirectusItemModel {
  DirectusPolicie.creator(super.data) : super.creator();

  @override
  String? get itemName => "directus_policies";

  static DirectusPolicieModelColums get cols => DirectusPolicieModelColums();

  String? get name => getValue(cols.name);

  String? get incon => getValue(cols.icon);

  String? get description => getValue(cols.description);

  String? get ipAccess => getValue(cols.ipAccess);

  bool? get enforceFta => getValue(cols.enforceFfa);
  bool? get adminAccess => getValue(cols.adminAccess);
  bool? get appAccess => getValue(cols.appAccess);

  List<DirectusUser>? get users =>
      getObjectList(cols.users, (data) => DirectusUser.creator(data));

  List<Map<String, dynamic>>? get permissions => getValue(cols.permissions);
}
