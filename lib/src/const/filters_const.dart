class DirectusFilter {
  ///Logical operator OR
  ///You can nest or group multiple rules using the _and or _or logical operators. Each logical operator holds an array of Filter Rules, allowing for more complex filtering. Also note in the example that Logical Operators can be sub-nested into Logical Operators. However, they cannot be sub-nested into Filter Rules.
  ///`{
  ///"_or": [
  ///		{
  ///			"_and": [
  ///				{
  ///					"user_created": {
  ///						"_eq": "$CURRENT_USER"
  ///					}
  ///				},
  ///				{
  ///					"status": {
  ///						"_in": ["published", "draft"]
  ///					}
  ///				}
  ///			]
  ///		},
  ///		{
  ///			"_and": [
  ///				{
  ///					"user_created": {
  ///						"_neq": "$CURRENT_USER"
  ///					}
  ///				},
  ///				{
  ///					"status": {
  ///						"_in": ["published"]
  ///					}
  ///				}
  ///			]
  ///		}
  ///	]
  ///}`
  static String or = "_or";

  ///Logical operator AND
  ///You can nest or group multiple rules using the _and or _or logical operators. Each logical operator holds an array of Filter Rules, allowing for more complex filtering. Also note in the example that Logical Operators can be sub-nested into Logical Operators. However, they cannot be sub-nested into Filter Rules.
  ///`{
  ///"_or": [
  ///		{
  ///			"_and": [
  ///				{
  ///					"user_created": {
  ///						"_eq": "$CURRENT_USER"
  ///					}
  ///				},
  ///				{
  ///					"status": {
  ///						"_in": ["published", "draft"]
  ///					}
  ///				}
  ///			]
  ///		},
  ///		{
  ///			"_and": [
  ///				{
  ///					"user_created": {
  ///						"_neq": "$CURRENT_USER"
  ///					}
  ///				},
  ///				{
  ///					"status": {
  ///						"_in": ["published"]
  ///					}
  ///				}
  ///			]
  ///		}
  ///	]
  ///}`
  static String and = "_and";

  ///Equal to
  static String equals = "_eq";

  ///Not equal to
  static String doesntEqual = "_neq";

  ///Less than
  static String lessThan = "_lt";

  ///Less than or equal to
  static String lessThanOrEqualTo = "_lte";

  ///Greater than
  static String greaterThan = "_gt";

  ///Greater than or equal to
  static String greaterThanOrEqualTo = "_gte";

  ///Matches any of the values
  static String isOneOf = "_in";

  ///Doesn't match any of the values
  static String isNotOneOf = "_nin";

  ///Is null
  static String isNull = "_null";

  ///Is not null
  static String isntNull = "_nnuul";

  ///Contains the substring
  static String contains = "_contains";

  ///Doesn't contain the substring
  static String coesntContain = "_ncontains";

  ///Starts with
  static String startsWith = "_starts_with";

  ///Doesn't start with
  static String doesntStartWith = "_nstarts_with";

  ///Ends with
  static String endsWith = "_ends_with";

  ///Doesn't end with
  static String doesntEndWith = "_nends_with";

  ///Is between two values (inclusive)
  static String isBetween = "_between";

  ///Is not between two values (inclusive)
  static String isntBetween = "_nbetween";

  ///Is empty (null or falsy)
  static String isEmpty = "_empty";

  ///Is not empty (null or falsy)
  static String isntEmpty = "_nempty";

  ///Value intersects a given point
  static String intersects = "_intersects";

  ///Value does not intersect a given point
  static String doesntIntersect = "_nintersects";

  ///Value is in a bounding box
  static String intersectsBoundingBox = "_intersects_bbox";

  ///Value is not in a bounding box
  static String doesntIntersectBoundingBox = "_nintersects_bbox";
}
