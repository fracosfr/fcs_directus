import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/models/directus_policie.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/modules/user/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModPolicie {
  ModPolicie(this._requestManager);

  final RequestManager _requestManager;

  Future<DirectusPolicie?> get(String id) async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl("${UserUrls.policie}$id"),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      return DirectusPolicie.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DirectusPolicie>> getMany({DirectusParams? params}) async {
    params ??= DirectusParams();
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(UserUrls.policie),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusPolicie> users = [];
      for (final user in mapData) {
        users.add(DirectusPolicie.creator(user));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }
}
