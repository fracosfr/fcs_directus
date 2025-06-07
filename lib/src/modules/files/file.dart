import 'dart:typed_data';

import 'package:fcs_directus/src/errors/error_parser.dart';
import 'package:fcs_directus/src/models/directus_file.dart';
import 'package:fcs_directus/src/modules/files/urls.dart';
import 'package:fcs_directus/src/modules/item/params.dart';
import 'package:fcs_directus/src/request/directus_request.dart';
import 'package:fcs_directus/src/request/request_manager.dart';

class ModFile {
  ModFile(this._requestManager);

  final RequestManager _requestManager;

  Future<Uint8List?> getAsset(String id) async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl("${FileUrls.asset}$id"),
      method: HttpMethod.asset,
    );

    return response.bodyBytes;
  }

  Future<DirectusFile?> get(String id) async {
    final params = DirectusParams(fields: ["*.*"]);
    final response = await _requestManager.executeRequest(
      url: params.generateUrl("${FileUrls.base}$id"),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      return DirectusFile.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DirectusFile>> getMany({DirectusParams? params}) async {
    params ??= DirectusParams();
    params.combine(DirectusParams(fields: ["*.*"]));

    final response = await _requestManager.executeRequest(
      url: params.generateUrl(FileUrls.base),
      method: HttpMethod.get,
    );

    ErrorParser(response).sendError();
    try {
      final mapData = response.toList();
      final List<DirectusFile> users = [];
      for (final user in mapData) {
        users.add(DirectusFile.creator(user));
      }
      return users;
    } catch (e) {
      rethrow;
    }
  }

  Future<DirectusFile?> upload(String filePath, {String? folderId}) async {
    final response = await _requestManager.uploadFile(
      url: FileUrls.base,
      filePath: filePath,
      data: {"folder": folderId ?? ""},
    );

    ErrorParser(response).sendError();

    try {
      return DirectusFile.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<DirectusFile?> update(DirectusFile file) async {
    final response = await _requestManager.executeRequest(
      url: "${FileUrls.base}${file.identifier}",
      method: HttpMethod.patch,
      data: file.toMap(),
    );
    ErrorParser(response).sendError();

    try {
      return DirectusFile.creator(response.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> delete(DirectusFile file) async {
    final request = await _requestManager.executeRequest(
      url: "${FileUrls.base}${file.identifier}",
      method: HttpMethod.delete,
      parseJson: false,
    );

    return request.rawData.isEmpty;
  }
}
