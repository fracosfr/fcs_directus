class FcsDirectusRequestManager {
  String? _token;
  String? _renewToken;
  String? _serverUrl;

  void setStaticToken({required String? staticToken}) {
    _token = staticToken;
  }

  void setServerUrl({required String? url}) {
    _serverUrl = url;
  }

  bool _refreshToken() {
    print("REFRESH TOKEN");
    return false;
  }
}
