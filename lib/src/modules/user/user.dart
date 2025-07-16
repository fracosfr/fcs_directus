import 'package:fcs_directus/fcs_directus.dart';
import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/modules/user/urls.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModUser {
  ModUser(this._requestManager);

  final RequestManager _requestManager;

  Future<DirectusUser?> get me async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl(UserUrls.getCurrent),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      return DirectusUser.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> acceptInvite(
      {required String token, required String password}) async {
    final response = await _requestManager.executeRequest(
      url: "${UserUrls.base}invite/accept",
      authentification: false,
      method: HttpMethod.post,
      data: {"token": token, "password": password},
    );
    ErrorParser(response).sendError();

    return response.rawData.isEmpty;
  }

  Future<bool> changePassword(String newPassword) async {
    final user = await me;
    user?.password = newPassword;
    if (user == null) return false;
    return (await update(user).onError((error, stackTrace) => null)) != null;
  }

  Future<(String secret, String otpauthUrl)> tfaGenerate(
      {required String password}) async {
    final response = await _requestManager.executeRequest(
      url: UserUrls.generateTfa,
      method: HttpMethod.post,
      data: {"password": password},
    );
    ErrorParser(response).sendError();

    return (
      response.toMap()["secret"].toString(),
      response.toMap()["otpauth_url"].toString()
    );
  }

  Future<bool> tfaEnable({required String secret, required String code}) async {
    final response = await _requestManager.executeRequest(
      url: UserUrls.enableTfa,
      method: HttpMethod.post,
      data: {"secret": secret, "otp": code},
    );
    ErrorParser(response).sendError();

    return response.rawData.isEmpty;
  }

  Future<bool> tfaDisable({required String code}) async {
    final response = await _requestManager.executeRequest(
      url: UserUrls.disableTfa,
      method: HttpMethod.post,
      data: {"otp": code},
    );
    ErrorParser(response).sendError();

    return response.rawData.isEmpty;
  }

  Future<DirectusUser?> get(String id) async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl("${UserUrls.base}$id"),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      return DirectusUser.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DirectusUser>> getMany({DirectusParams? params}) async {
    params ??= DirectusParams();
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(UserUrls.base),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusUser> users = [];
      for (final user in mapData) {
        users.add(DirectusUser.creator(user));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }

  Future<DirectusUser?> create(DirectusUser user) async {
    final response = await _requestManager.executeRequest(
      url: UserUrls.base,
      method: HttpMethod.post,
      data: user.toMap(onlyChanges: false),
    );
    ErrorParser(response).sendError();

    try {
      return DirectusUser.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<DirectusUser?> update(DirectusUser user) async {
    final response = await _requestManager.executeRequest(
      url: "${UserUrls.base}${user.identifier}",
      method: HttpMethod.patch,
      data: user.toMap(),
    );
    ErrorParser(response).sendError();

    try {
      return DirectusUser.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> delete(DirectusUser user) async {
    final request = await _requestManager.executeRequest(
      url: "${UserUrls.base}${user.identifier}",
      method: HttpMethod.delete,
      parseJson: false,
    );

    return request.rawData.isEmpty;
  }
}
