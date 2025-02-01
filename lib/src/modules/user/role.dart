import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/models/directus_role.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/modules/user/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModRole {
  ModRole(this._requestManager);

  final RequestManager _requestManager;

  Future<DirectusUserRole?> get(String id) async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl("${UserUrls.role}$id"),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      return DirectusUserRole.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DirectusUserRole>> getMany({DirectusParams? params}) async {
    params ??= DirectusParams();
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(UserUrls.role),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusUserRole> users = [];
      for (final user in mapData) {
        users.add(DirectusUserRole.creator(user));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }
}
