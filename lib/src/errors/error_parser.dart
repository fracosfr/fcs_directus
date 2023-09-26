import 'package:fcs_directus/src/errors/errors.dart';

class ErrorParser {
  String _code = "";
  String _message = "";
  bool _errorDetected = false;

  String get code => _code;
  String get message => _message;
  bool get errorDetected => _errorDetected;
  DirectusError? get error => _error;

  DirectusError? _error;

  ErrorParser(dynamic data) {
    try {
      _error = null;
      if (data is Map<String, dynamic>) {
        if (data.keys.contains("errors")) {
          final error = data["errors"][0];
          _message =
              error["message"] ?? "Directus send an unknow response data.";
          final extensions = error["extensions"] ?? {};
          _code = extensions["code"] ?? "UNKNOW";
          _errorDetected = true;
          _error = _getError();
        }
      }
    } catch (_) {
      _error = DirectusErrorUnknow(
          "An error was occured when parsing directus errors");
    }
  }

  sendError() {
    if (_error != null) throw _error!;
  }

  DirectusError _getError() {
    switch (code) {
      case "INVALID_CREDENTIALS":
        return DirectusErrorAuthCredentials(code, message);
      case "INVALID_PAYLOAD":
        return DirectusErrorAuthInvalidPayload(code, message);
      case "FORBIDDEN":
        return DirectusErrorAuthForbidden(code, message);
      case "INTERNAL_SERVER_ERROR":
        return DirectusErrorInternal();
      default:
        return DirectusErrorAuthUnknow(code, message);
    }
  }
}
