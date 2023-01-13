class DirectusDynVar {
  /// The primary key of the currently authenticated user
  static String currentUser = "\$CURRENT_USER";

  /// The primary key of the role for the currently authenticated user
  static String currentRole = "\$CURRENT_ROLE";

  /// The current timestamp
  static String now = "\$NOW";

  /// The current timestamp plus/minus a given distance, for example [nowAjust("-1 year")], [nowAjust("+2 hours")]
  static String nowAjust(String adjustement) {
    return "\$NOW($adjustement)";
  }
}
