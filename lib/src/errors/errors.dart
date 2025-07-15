abstract class DirectusError {
  String _message = "Internal error!";
  int _code = 1;

  String get message => _message;
  int get code => _code;

  @override
  String toString() => "ERROR ($_code) : $_message";
}

//class DirectusErrorPayload extends DirectusError {}

class DirectusErrorInternal extends DirectusError {
  DirectusErrorInternal() {
    _message = "Internal Directus server error!";
    _code = 1;
  }
}

class DirectusErrorUnknow extends DirectusError {
  DirectusErrorUnknow(String message) {
    _message = message;
    _code = 9000;
  }
}

class DirectusErrorHttp extends DirectusError {
  DirectusErrorHttp(String msg) {
    _message = msg;
    _code = 100;
  }
}

class DirectusErrorHttpJsonException extends DirectusError {
  DirectusErrorHttpJsonException() {
    _message =
        "The result of the request is not a Json value, or can't be read as Json value.";
    _code = 101;
  }
}

class DirectusErrorHttpFilterInvalid extends DirectusError {
  DirectusErrorHttpFilterInvalid() {
    _message = "The filter used is not valid, please verify it.";
    _code = 120;
  }
}

class DirectusErrorHttpFilterValue extends DirectusError {
  DirectusErrorHttpFilterValue() {
    _message =
        "The filter final value can only be type of STRING/INT/DOUBLE/BOOLEAN";
    _code = 121;
  }
}

class DirectusErrorHttpFilterTooDeep extends DirectusError {
  DirectusErrorHttpFilterTooDeep() {
    _message =
        "The filter is too deep for the GET request, use SEARCH request instead.";
    _code = 123;
  }
}

abstract class DirectusErrorAuth extends DirectusError {
  String _identifier = "";
  DirectusErrorAuth(String code, String msg) {
    _message = msg;
    _identifier = code;
  }

  String get identifier => _identifier;

  @override
  String toString() => "ERROR ($_code [$_identifier]) : $_message";
}

class DirectusErrorAuthCredentials extends DirectusErrorAuth {
  DirectusErrorAuthCredentials(super.code, super.msg) {
    _code = 1000;
  }
}

class DirectusErrorAuthInvalidPayload extends DirectusErrorAuth {
  DirectusErrorAuthInvalidPayload(super.code, super.msg) {
    _code = 1001;
  }
}

class DirectusErrorAuthForbidden extends DirectusErrorAuth {
  DirectusErrorAuthForbidden(super.code, super.msg) {
    _code = 1002;
  }
}

class DirectusErrorInvalidOtp extends DirectusErrorAuth {
  DirectusErrorInvalidOtp(super.code, super.msg) {
    _code = 1003;
  }
}

class DirectusErrorInvalidIp extends DirectusErrorAuth {
  DirectusErrorInvalidIp(super.code, super.msg) {
    _code = 1004;
  }
}

class DirectusErrorTokenExpired extends DirectusErrorAuth {
  DirectusErrorTokenExpired(super.code, super.msg) {
    _code = 1005;
  }
}

class DirectusErrorInvalidToken extends DirectusErrorAuth {
  DirectusErrorInvalidToken(super.code, super.msg) {
    _code = 1006;
  }
}

class DirectusErrorAuthUnknow extends DirectusErrorAuth {
  DirectusErrorAuthUnknow(super.code, super.msg) {
    _code = 1010;
  }
}

class DirectusErrorObjectClassName extends DirectusError {
  DirectusErrorObjectClassName(String className) {
    _message =
        "Please use a legal Class name for $className or override getter itemName";
    _code = 2000;
  }
}

class DirectusErroFailedValidation extends DirectusErrorAuth {
  DirectusErroFailedValidation(super.code, super.msg) {
    _code = 2001;
  }
}

class DirectusErrorInvalidQuery extends DirectusErrorAuth {
  DirectusErrorInvalidQuery(super.code, super.msg) {
    _code = 2002;
  }
}

class DirectusErrorUnsuportedMediaType extends DirectusErrorAuth {
  DirectusErrorUnsuportedMediaType(super.code, super.msg) {
    _code = 2003;
  }
}

class DirectusErrorRequestExceeded extends DirectusErrorAuth {
  DirectusErrorRequestExceeded(super.code, super.msg) {
    _code = 2004;
  }
}

class DirectusErrorRouteNotFound extends DirectusErrorAuth {
  DirectusErrorRouteNotFound(super.code, super.msg) {
    _code = 2005;
  }
}

class DirectusErrorServiceUnavailable extends DirectusErrorAuth {
  DirectusErrorServiceUnavailable(super.code, super.msg) {
    _code = 2006;
  }
}

class DirectusErrorUnprocessableContent extends DirectusErrorAuth {
  DirectusErrorUnprocessableContent(super.code, super.msg) {
    _code = 2007;
  }
}
