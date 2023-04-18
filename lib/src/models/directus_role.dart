import 'package:fcs_directus/src/models/item_model.dart';

class DirectusUserRoleModelColums {
  final String name = "name";
  final String icon = "icon";
  final String description = "description";
  final String ipAccess = "ip_access";
  final String enforceFfa = "enforce_tfa";
  final String adminAccess = "admin_access";
  final String appAccess = "app_access";
  final String users = "users";
}

class DirectusUserRole extends DirectusItemModel {
  DirectusUserRole.creator(super.data) : super.creator();

  @override
  String? get itemName => "directus_roles";

  static DirectusUserRoleModelColums get cols => DirectusUserRoleModelColums();

  String? get name => getValue(cols.name);
  set name(String? value) => setValue(cols.name, value);

  String? get icon => getValue(cols.icon);
  set icon(String? value) => setValue(cols.icon, value);

  String? get description => getValue(cols.description);
  set description(String? value) => setValue(cols.description, value);

  String? get ipAccess => getValue(cols.ipAccess);
  set ipAccess(String? value) => setValue(cols.ipAccess, value);

  bool get enforceFfa => getValue(cols.enforceFfa) ?? false;
  set enforceFfa(bool value) => setValue(cols.enforceFfa, value);

  bool get appAccess => getValue(cols.appAccess) ?? false;
  set appAccess(bool value) => setValue(cols.appAccess, value);

  bool get adminAccess => getValue(cols.adminAccess) ?? false;
  set adminAccess(bool value) => setValue(cols.adminAccess, value);

  List<String>? get users => getValue(cols.users);
  set users(List<String>? value) => setValue(cols.users, value);
}
