import 'package:dio/dio.dart';

import '../core/directus_http_client.dart';

/// Service d'accès aux métriques Prometheus de Directus (`GET /metrics`).
///
/// L'endpoint n'existe que si `METRICS_ENABLED=true`. Il est protégé par l'un
/// des jetons `METRICS_TOKENS` (en-tête `Authorization: Bearer <token>`).
///
/// ```dart
/// final text = await client.metrics.getMetrics(token: 'metrics-token');
/// print(text); // format d'exposition Prometheus
/// ```
class MetricsService {
  final DirectusHttpClient _httpClient;

  MetricsService(this._httpClient);

  /// Récupère les métriques au format texte Prometheus.
  ///
  /// [token] Jeton `METRICS_TOKENS` ; sinon le token de session courant est envoyé.
  Future<String> getMetrics({String? token}) async {
    final response = await _httpClient.get<String>(
      '/metrics',
      options: Options(
        responseType: ResponseType.plain,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );
    return response.data ?? '';
  }
}
