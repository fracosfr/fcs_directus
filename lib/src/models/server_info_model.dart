import 'package:fcs_directus/src/models/item_model.dart';

class DirectusServerInfoModel extends DirectusItemModel {
  DirectusServerInfoModel.fromDirectus(super.data) : super.creator();

  @override
  String? get itemName => null;

  String get projecName => getValue("project.project_name") ?? "";
  String get defaultLanguage => getValue("project.default_language") ?? "";

  int get rateLimitPoints => getValue("rateLimit.points") ?? 0;
  int get rateLimitDuration => getValue("rateLimit.duration") ?? 0;

  List<dynamic> get execAllowedModules =>
      getValue("flows.execAllowedModules") ?? [];

  String get directusVersion => getValue("directus.version") ?? "";

  String get nodeVersion => getValue("node.version") ?? "";
  int get nodeUptime => getValue("node.uptime") ?? 0;

  String get osType => getValue("os.type") ?? "Unknow";
  String get osVersion => getValue("os.version") ?? "";
  int get osUptime => getValue("os.uptime") ?? 0;
  int get osTotalMem => getValue("os.totalmem") ?? 0;
}
