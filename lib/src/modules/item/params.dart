import 'package:fcs_directus/fcs_directus.dart';

class DirectusParams {
  ///Used to search items in a collection that matches the filter's conditions.
  ///The filter param follows the Filter Rules spec, which includes additional information on logical operators (AND/OR), nested relational filtering, and dynamic variables.
  ///Examples
  ///Retrieve all items where first_name equals "Rijk"
  ///
  ///json
  ///{
  ///	"first_name": {
  ///		[DirectusFilterVar.equals]: "Rijk"
  ///	}
  ///}
  ///Retrieve all items in one of the following categories: "vegetables", "fruit"
  ///
  ///json
  ///{
  ///	"categories": {
  ///		[DirectusFilterVar.isOneOf]: ["vegetables", "fruit"]
  ///	}
  ///}
  DirectusFilterContructor? filter;
  DirectusParamsAggregate? aggregate;
  int? limit;
  int? offset;
  int? page;
  String? search;
  List<String>? fields;
  List<String>? sort;

  DirectusParams({
    this.aggregate,
    this.fields,
    this.limit,
    this.filter,
    this.offset,
    this.page,
    this.search,
    this.sort,
  });

  combine(DirectusParams params) {
    aggregate ??= params.aggregate;
    fields ??= params.fields;
    limit ??= params.limit;
    filter ??= params.filter;
    offset ??= params.offset;
    page ??= params.page;
    search ??= params.search;
    sort ??= params.sort;
  }

  String generateUrl(String url) {
    String ext = "";

    if (fields != null) {
      String f = "";
      for (final s in fields!) {
        f += f.isEmpty ? s : ",$s";
      }
      ext = _addParam(ext, "fields=$f");
    }

    if (filter != null) {
      ext = _addParam(ext, "filter=${filter?.json}");
    }

    if (search != null) {
      ext = _addParam(ext, "search=$search");
    }

    if (sort != null) {
      for (final s in sort!) {
        ext = _addParam(ext, "sort[]=$s");
      }
    }

    if (limit != null) {
      ext = _addParam(ext, "limit=$limit");
    }

    if (offset != null) {
      ext = _addParam(ext, "offset=$offset");
    }

    if (page != null) {
      ext = _addParam(ext, "page=$page");
    }

    if (aggregate != null) {
      ext = _addParam(
          ext, "aggregate[${aggregate!.type.value}]=${aggregate!.field}");

      if (aggregate!.groupBy != null) {
        for (final s in aggregate!.groupBy!) {
          ext = _addParam(ext, "groupBy[]=$s");
        }
      }
    }

    return "$url$ext";
  }

  String _addParam(String ext, String param) =>
      "$ext${ext.isEmpty ? "?" : "&"}$param";
}

class DirectusParamsAggregate {
  DirectusAggregateType type;
  String field;
  List<String>? groupBy;

  DirectusParamsAggregate(
      {required this.type, required this.field, this.groupBy});
}
