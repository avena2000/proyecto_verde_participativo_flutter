import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import '../models/accion.dart';
import '../models/medalla.dart';

class ApiService {
  late final Dio _dio;
  final notificationService = NotificationService();
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_URL'] ?? 'http://localhost:3000/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptores para manejo global de errores y tokens
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Aquí puedes agregar el token de autenticación si existe
        final token = dotenv.env['AUTH_TOKEN'];
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Manejo global de errores
        if (error.response?.statusCode == 401) {}
        return handler.next(error);
      },
    ));
  }

  // Método genérico para GET
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método genérico para POST
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método genérico para PUT
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método genérico para DELETE
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response =
          await _dio.delete(path, queryParameters: queryParameters);
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Método específico para subir archivos
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? extraData,
    T Function(dynamic)? parser,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });

      final response = await _dio.post(path, data: formData);
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Implementación específica para acciones
  Future<List<Accion>> getAcciones() async {
    return get<List<Accion>>(
      '/acciones',
      parser: (data) => (data as List)
          .map((json) => Accion.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> subirAccion({
    required String userId,
    required String tipo,
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    String tipoAccion;
    switch (tipo.toLowerCase()) {
      case 'ayuda':
        tipoAccion = 'ayuda';
        break;
      case 'descubrimiento':
        tipoAccion = 'descubrimiento';
        break;
      case 'alerta':
        tipoAccion = 'alerta';
        break;
      default:
        throw Exception('Tipo de acción no válido');
    }

    await uploadFile(
      '/users/$userId/actions',
      filePath: imagePath,
      fileField: 'imagen',
      extraData: {
        'tipo_accion': tipoAccion,
        'latitud': latitude,
        'longitud': longitude,
      },
    );
  }

  // Implementación específica para medallas
  Future<List<Medalla>> getMedallas() async {
    return get<List<Medalla>>(
      '/medallas',
      parser: (data) => (data as List)
          .map((json) => Medalla.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<MedallaUsuario>> getMedallasUsuario(String userId) async {
    return get<List<MedallaUsuario>>(
      '/users/$userId/medallas',
      parser: (data) => (data as List)
          .map((json) => MedallaUsuario.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Error de conexión');
      case DioExceptionType.sendTimeout:
        return Exception('Error de tiempo de espera en la conexión');
      case DioExceptionType.receiveTimeout:
        return Exception('Error de tiempo de espera en la conexión');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        switch (statusCode) {
          case 400:
            return Exception(data?['message'] ?? 'Solicitud incorrecta');
          case 401:
            return Exception('No autorizado');
          case 403:
            return Exception('Acceso denegado');
          case 404:
            return Exception('Recurso no encontrado');
          case 409:
            return Exception(e.response?.data ?? 'Conflicto con el recurso');
          case 500:
            return Exception('Error interno del servidor');
          default:
            return Exception('Error en la respuesta del servidor');
        }
      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada');
      default:
        return Exception('Error de conexión al servidor');
    }
  }
}
