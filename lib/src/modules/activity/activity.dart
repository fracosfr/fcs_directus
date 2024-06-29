import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/models/directus_activity.dart';
import 'package:fcs_directus/src/modules/activity/urls.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/request/directus_filter.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModActivity {
  ModActivity(this._requestManager);

  final RequestManager _requestManager;

  Future<List<DirectusActivity>> getMany({DirectusParams? params}) async {
    params ??= DirectusParams();
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(ActivityUrls.base),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusActivity> users = [];
      for (final user in mapData) {
        users.add(DirectusActivity.creator(user));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }

  Future<DirectusActivity?> getById({
    required String id,
  }) async {
    DirectusParams params = DirectusParams(filter: Filter.equal("id", id));
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(ActivityUrls.base),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusActivity> users = [];
      for (final user in mapData) {
        users.add(DirectusActivity.creator(user));
      }
      return users.first;
    } catch (e) {
      rethrow;
    }
  }
}
