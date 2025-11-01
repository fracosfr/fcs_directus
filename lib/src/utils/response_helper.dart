import 'package:dio/dio.dart';

/// Helper pour extraire les données d'une réponse Directus
///
/// Directus peut retourner une réponse 204 No Content sans body dans certains cas
/// (notamment lors de certaines opérations create/update).
/// Cette fonction gère ce cas en retournant null au lieu de lancer une exception.
T? extractResponseData<T>(Response response, T Function(dynamic) extractor) {
  // Si pas de data ou pas de clé 'data', retourner null
  if (response.data == null || response.data is! Map) {
    return null;
  }

  final data = response.data as Map<String, dynamic>;
  if (!data.containsKey('data')) {
    return null;
  }

  return extractor(data['data']);
}

/// Extrait une Map depuis response.data['data']
Map<String, dynamic>? extractMapData(Response response) {
  return extractResponseData<Map<String, dynamic>>(
    response,
    (data) => data as Map<String, dynamic>,
  );
}

/// Extrait une List depuis response.data['data']
List? extractListData(Response response) {
  return extractResponseData<List>(response, (data) => data as List);
}

/// Vérifie si la réponse contient des données
bool hasResponseData(Response response) {
  return response.data != null &&
      response.data is Map &&
      (response.data as Map).containsKey('data');
}
