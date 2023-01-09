class FcsDirectusRequestManager {
  String? _token;
  String? _renewToken;
  String? _serverUrl;

  void setToken({required String? token}) {
    _token = token;
  }

  void setServerUrl({required String? url}) {
    _serverUrl = url;
  }

  bool _refreshToken() {
    print("REFRESH TOKEN");
    return false;
  }
}
