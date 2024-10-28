import 'package:fcs_directus/src/models/item_model.dart';
import 'package:fcs_directus/src/models/server_health_pg_model.dart';

class DirectusServerHealthModel extends DirectusItemModel {
  DirectusServerHealthModel.fromDirectus(super.data) : super.creator();

  @override
  String? get itemName => null;

  String get status => getValue("status") ?? "";
  String get releaseId => getValue("releaseId") ?? "";
  String get serviceId => getValue("serviceId") ?? "";

  List<DirectusServerHealthStatusModel> get responseTime => getObjectList(
      "checks.pg:responseTime",
      (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get connectionsAvailable =>
      getObjectList("checks.pg:connectionsAvailable",
          (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get connectionsUsed => getObjectList(
      "checks.pg:connectionsUsed",
      (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get cacheResponseTime => getObjectList(
      "checks.cache:responseTime",
      (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get rateLimiterResponseTime =>
      getObjectList("checks.rateLimiter:responseTime",
          (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get storageCloudResponseTime =>
      getObjectList("checks.storage:cloud:responseTime",
          (data) => DirectusServerHealthStatusModel.fromDirectus(data));

  List<DirectusServerHealthStatusModel> get emailConnection => getObjectList(
      "checks.email:connection",
      (data) => DirectusServerHealthStatusModel.fromDirectus(data));
}
