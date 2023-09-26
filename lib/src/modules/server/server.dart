import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/models/server_health_model.dart';
import 'package:fcs_directus/src/models/server_info_model.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModServer {
  final RequestManager _requestManager;

  ModServer(this._requestManager);

  Future<Map<String, dynamic>> openApi() async {
    final response = await _requestManager.executeRequest(
      url: "/server/specs/oas",
    );
    ErrorParser(response).sendError();
    return response.data;
  }

  Future<bool> ping() async {
    final response = await _requestManager.executeRequest(
      url: "/server/ping",
      parseJson: false,
    );
    return (response.data["data"] ?? "") == "pong";
  }

  Future<DirectusServerInfoModel> info() async {
    final response = await _requestManager.executeRequest(url: "/server/info");
    ErrorParser(response).sendError();
    return DirectusServerInfoModel.fromDirectus(response.toMap());
  }

  Future<DirectusServerHealthModel> health() async {
    final response =
        await _requestManager.executeRequest(url: "/server/health");
    ErrorParser(response).sendError();
    return DirectusServerHealthModel.fromDirectus(response.toMap());
  }
}
