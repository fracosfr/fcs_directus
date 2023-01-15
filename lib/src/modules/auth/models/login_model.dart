import 'package:fcs_directus/src/models/item_model.dart';

class LoginModel extends DirectusItemModel {
  String get accessToken => getValue("access_token") ?? "";
  String get refreshToken => getValue("refresh_token") ?? "";
  int get expires => getValue("expires") ?? 0;

  LoginModel.fromResponse(super.response) : super.fromDirectus();
}
