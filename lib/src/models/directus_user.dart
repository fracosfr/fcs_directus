import 'package:fcs_directus/fcs_directus.dart';

class DirectusUserModelColums {
  final String firstName = "first_name";
  final String lastName = "last_name";
  final String email = "email";
  final String location = "location";
  final String title = "title";
  final String description = "description";
  final String tags = "tags";
  final String avatar = "avatar";
  final String language = "language";
  final String theme = "theme";
  final String tfaSecret = "tfa_secret";
  final String status = "status";
  final String role = "role";
  final String lastAccess = "last_access";
  final String lastPage = "last_page";
  final String provider = "provider";
  final String externalIdentifier = "external_identifier";
  final String authData = "auth_data";
  final String emailNotifications = "email_notifications";
  final String password = "password";
  final String policies = "policies";
}

class DirectusUser extends DirectusItemModel {
  DirectusUser.creator(super.data) : super.creator();
  DirectusUser(
      {String? firstName,
      String? lastName,
      String? title,
      required String email,
      String? password,
      Map<String, dynamic>? customs}) {
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    if (password != null) this.password = password;
    this.title = title;

    if (customs != null) setCustomMultiple(customs);
  }

  Map<String, dynamic> toSafeJson() {
    final data = toJson();
    data.remove("role");
    data.remove("policies");
    return data;
  }

  @override
  int get cascadeLevel => 2;

  @override
  bool get disableCache => true;

  @override
  String? get itemName => "directus_users";

  static DirectusUserModelColums get cols => DirectusUserModelColums();

  String? get firstName => getValue(cols.firstName);
  set firstName(String? value) => setValue(cols.firstName, value);

  DirectusFile? get avatarFile => getObject(cols.avatar, DirectusFile.creator);
  set avatar(String? value) => setValue(cols.avatar, value);

  String? get lastName => getValue(cols.lastName);
  set lastName(String? value) => setValue(cols.lastName, value);

  String? get email => getValue(cols.email);
  set email(String? value) => setValue(cols.email, value);

  String? get location => getValue(cols.location);
  set location(String? value) => setValue(cols.location, value);

  String? get title => getValue(cols.title);
  set title(String? value) => setValue(cols.title, value);

  String? get description => getValue(cols.description);
  set description(String? value) => setValue(cols.description, value);

  List<String>? get tags => getValue(cols.tags);
  set tags(List<String>? value) => setValue(cols.tags, value);

  //AVATAR

  String? get language => getValue(cols.language);
  set language(String? value) => setValue(cols.language, value);

  DirectusTheme get theme {
    final String value = getValue(cols.theme) ?? "auto";
    return DirectusTheme.values.firstWhere(
      (element) => element.name == value,
      orElse: () => DirectusTheme.auto,
    );
  }

  set theme(DirectusTheme theme) => setValue(cols.theme, theme.name);

  String? get tfaSecret => getValue(cols.tfaSecret);
  set tfaSecret(String? value) => setValue(cols.tfaSecret, value);

  DirectusUserStatus get status {
    final String value = getValue(cols.status) ?? "draft";
    return DirectusUserStatus.values.firstWhere(
      (element) => element.name == value,
      orElse: () => DirectusUserStatus.draft,
    );
  }

  set status(DirectusUserStatus status) => setValue(cols.status, status.name);

  //ROLE AS OBJECT ?
  DirectusUserRole get role =>
      getObject(cols.role, (data) => DirectusUserRole.creator(data));

  set role(DirectusUserRole value) => setValue(cols.role, value.toMap());

  List<DirectusUserAccess> get policies =>
      getObjectList(cols.policies, DirectusUserAccess.creator);

  DateTime? get lastAccess => getValue(cols.lastAccess);
  set lastAccess(DateTime? value) => setValue(cols.lastAccess, value);

  String? get lastPage => getValue(cols.lastPage);

  String? get provider => getValue(cols.provider);
  set provider(String? value) => setValue(cols.provider, value);

  String? get externalIdentifier => getValue(cols.externalIdentifier);
  set externalIdentifier(String? value) =>
      setValue(cols.externalIdentifier, value);

  String? get authData => getValue(cols.authData);
  set authData(String? value) => setValue(cols.authData, value);

  bool get emailNotification => getValue(cols.emailNotifications) ?? false;
  set emailNotification(bool value) => setValue(cols.emailNotifications, value);

  set password(String value) => setValue(cols.password, value);

  T? getCustom<T>(String key) => getValue(key);
  void setCustom<T>(String key, T value) => setValue(key, value);
  void setCustomMultiple(Map<String, dynamic> data) {
    for (final key in data.keys) {
      setValue(key, data[key]);
    }
  }
}
