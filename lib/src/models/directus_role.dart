import 'package:fcs_directus/fcs_directus.dart';

class DirectusUserRoleModelColums {
  final String name = "name";
  final String icon = "icon";
  final String description = "description";
  final String policies = "policies";
  final String parent = "parent";
  final String children = "children";
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

  List<DirectusUserAccess> get policies =>
      getObjectList(cols.policies, DirectusUserAccess.creator);
  //set policies(List<String>? value) => setValue(cols.policies, value);

  String? get parent => getValue(cols.parent);
  set parent(String? value) => setValue(cols.parent, value);

  List<String>? get children => getValue(cols.children);
  set children(List<String>? value) => setValue(cols.children, value);

  List<String>? get users => getValue(cols.users);
  set users(List<String>? value) => setValue(cols.users, value);
}
