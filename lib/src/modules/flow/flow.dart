import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModFlow {
  ModFlow(this._requestManager);
  final RequestManager _requestManager;
  Future<bool> runTriggerGet(
      {required String flowId, Map<String, dynamic> data = const {}}) async {
    String ext = "";
    for (String key in data.keys) {
      if (data[key] != null) {
        ext = "$ext${ext.isEmpty ? "?" : "&"}$key=${data[key]}";
      }
    }
    final res = await _requestManager.executeRequest(
      url: "/flows/trigger/$flowId$ext",
      parseJson: false,
      authentification: false,
    );
    return res.status == 200;
  }

  Future<bool> runTriggerPost(
      {required String flowId, Map<String, dynamic> data = const {}}) async {
    final res = await _requestManager.executeRequest(
      method: HttpMethod.post,
      url: "/flows/trigger/$flowId",
      data: data,
      parseJson: false,
      authentification: false,
    );
    return res.status == 200;
  }
}
