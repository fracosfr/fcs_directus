import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'directus_config.dart';
import '../exceptions/directus_exception.dart';

/// Client HTTP pour communiquer avec l'API Directus.
///
/// Cette classe encapsule Dio et gère les erreurs, l'authentification
/// et le formatage des requêtes/réponses.
class DirectusHttpClient {
  final DirectusConfig _config;
  final Dio _dio;
  final Logger _logger;

  String? _accessToken;
  String? _refreshToken;

  /// Récupère la configuration du client
  DirectusConfig get config => _config;

  /// Crée un nouveau client HTTP Directus
  DirectusHttpClient(this._config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _config.baseUrl,
          connectTimeout: _config.timeout,
          receiveTimeout: _config.timeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ..._config.headers ?? {},
          },
        ),
      ),
      _logger = Logger('DirectusHttpClient') {
    _setupInterceptors();

    if (_config.enableLogging) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.time}: ${record.message}');
      });
    }
  }

  /// Configure les intercepteurs Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Ajouter le token d'authentification si disponible
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }

          if (_config.enableLogging) {
            _logger.info('→ ${options.method} ${options.uri}');
            if (options.data != null) {
              _logger.fine('  Data: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (_config.enableLogging) {
            _logger.info(
              '← ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (_config.enableLogging) {
            _logger.severe('✗ ${error.requestOptions.uri}', error);
          }
          // Convertir l'erreur mais laisser Dio la gérer
          final directusError = _handleError(error);
          _logger.warning('Converted to: $directusError');
          return handler.next(error);
        },
      ),
    );
  }

  /// Définit les tokens d'authentification
  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Récupère le token d'accès actuel
  String? get accessToken => _accessToken;

  /// Récupère le token de rafraîchissement actuel
  String? get refreshToken => _refreshToken;

  /// Effectue une requête GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final result = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (result.statusCode == 204) {
        // Créer une réponse vide si le statut est 204
        return Response<T>(
          requestOptions: result.requestOptions,
          statusCode: 204,
          data: null,
        );
      }
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête PATCH
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final result = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (result.statusCode == 204) {
        // Créer une réponse vide si le statut est 204
        return Response<T>(
          requestOptions: result.requestOptions,
          statusCode: 204,
          data: null,
        );
      }
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final result = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (result.statusCode == 204) {
        // Créer une réponse vide si le statut est 204
        return Response<T>(
          requestOptions: result.requestOptions,
          statusCode: 204,
          data: null,
        );
      }
      return result;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gère les erreurs Dio et les convertit en exceptions Directus
  DirectusException _handleError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Une erreur est survenue';

    if (data is Map<String, dynamic>) {
      message =
          data['message']?.toString() ?? data['error']?.toString() ?? message;
    }

    // Extraire le code d'erreur Directus si présent
    String? errorCode;
    Map<String, dynamic>? extensions;

    if (data is Map<String, dynamic>) {
      // Format Directus standard
      if (data.containsKey('errors') &&
          data['errors'] is List &&
          (data['errors'] as List).isNotEmpty) {
        final firstError = (data['errors'] as List).first;
        if (firstError is Map<String, dynamic>) {
          extensions = firstError['extensions'] as Map<String, dynamic>?;
          errorCode = extensions?['code'] as String?;
          message = firstError['message'] as String? ?? message;
        }
      }
    }

    // Si on a un code d'erreur Directus, utiliser fromJson
    if (errorCode != null) {
      return DirectusException.fromJson({
        'message': message,
        'extensions': extensions,
      });
    }

    // Sinon, mapper selon le code HTTP
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DirectusNetworkException(
          message: 'Timeout: La requête a pris trop de temps',
          extensions: extensions,
        );

      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 400:
            return DirectusValidationException(
              message: message,
              statusCode: statusCode,
              extensions: extensions,
            );
          case 401:
            return DirectusAuthException(
              message: 'Non authentifié: $message',
              statusCode: statusCode,
              extensions: extensions,
            );
          case 403:
            return DirectusPermissionException(
              message: 'Permission refusée: $message',
              statusCode: statusCode,
              extensions: extensions,
            );
          case 404:
            return DirectusNotFoundException(
              message: 'Ressource non trouvée: $message',
              statusCode: statusCode,
              extensions: extensions,
            );
          default:
            if (statusCode != null && statusCode >= 500) {
              return DirectusServerException(
                message: 'Erreur serveur: $message',
                statusCode: statusCode,
                extensions: extensions,
              );
            }
            return DirectusException(
              message: message,
              statusCode: statusCode,
              extensions: extensions,
            );
        }

      case DioExceptionType.cancel:
        return DirectusException(
          message: 'Requête annulée',
          extensions: extensions,
        );

      case DioExceptionType.connectionError:
        return DirectusNetworkException(
          message: 'Erreur de connexion: Impossible de joindre le serveur',
          extensions: extensions,
        );

      default:
        return DirectusException(
          message: message,
          statusCode: statusCode,
          extensions: extensions,
        );
    }
  }

  /// Ferme le client HTTP
  void close() {
    _dio.close();
  }
}
