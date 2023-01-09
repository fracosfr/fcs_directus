class FcsDirectusRequestManager {
  String _token = "";
  String _renewToken = "";

  void setToken({required String token}) {
    _token = token;
  }

  bool _refreshToken() {
    print("REFRESH TOKEN");
    return false;
  }
}
