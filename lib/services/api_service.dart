import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:proyecto_verde_participativo/constants/api_codes.dart';
import 'package:proyecto_verde_participativo/models/api_response.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import '../models/accion.dart';
import '../models/medalla.dart';
import 'dart:typed_data';

class ApiService {
  late final Dio _dio;
  final notificationService = NotificationService();
  static final ApiService _instance = ApiService._internal();
  BuildContext? _context;

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

  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _context = context;
  }

  // Método genérico para GET
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool showMessages = false,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _processResponse<T>(response, parser, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  // Método genérico para POST
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool showMessages = false,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _processResponse<T>(response, parser, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  // Método genérico para PUT
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool showMessages = false,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _processResponse<T>(response, parser, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  // Método genérico para DELETE
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool showMessages = false,
  }) async {
    try {
      final response =
          await _dio.delete(path, queryParameters: queryParameters);
      return _processResponse<T>(response, parser, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  // Método específico para subir archivos
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? extraData,
    T Function(dynamic)? parser,
    bool showMessages = false,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });

      final response = await _dio.post(path, data: formData);
      return _processResponse<T>(response, parser, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  // Método para procesar respuestas con el nuevo formato
  T _processResponse<T>(
    Response response,
    T Function(dynamic)? parser,
    bool showMessages,
  ) {
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data,
      (data) => data,
    );

    if (apiResponse.isSuccess) {
      if (showMessages && _context != null) {
        notificationService.showSuccess(_context!, apiResponse.message);
      }

      if (parser != null && apiResponse.data != null) {
        return parser(apiResponse.data);
      }

      // Si no hay parser o no hay datos, devolvemos los datos directamente
      // o un valor por defecto según el tipo genérico
      if (apiResponse.data != null) {
        return apiResponse.data as T;
      } else {
        // Para tipos que pueden ser null
        return null as T;
      }
    } else {
      // Si no es exitoso, lanzamos una excepción con el mensaje de error
      final exception = Exception(apiResponse.errorMessage);
      if (showMessages && _context != null) {
        notificationService.showError(_context!, apiResponse.errorMessage);
      }
      throw exception;
    }
  }

  // Implementación específica para acciones
  Future<List<Accion>> getAcciones({bool showMessages = false}) async {
    return get<List<Accion>>(
      '/acciones',
      parser: (data) => (data as List)
          .map((json) => Accion.fromJson(json as Map<String, dynamic>))
          .toList(),
      showMessages: showMessages,
    );
  }

  Future<void> subirAccion({
    required String userId,
    required String tipo,
    required String imagePath,
    double? latitude,
    double? longitude,
    bool showMessages = false,
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
      showMessages: showMessages,
    );
  }

  // Implementación específica para medallas
  Future<List<Medalla>> getMedallas({bool showMessages = false}) async {
    return get<List<Medalla>>(
      '/medallas',
      parser: (data) => (data as List)
          .map((json) => Medalla.fromJson(json as Map<String, dynamic>))
          .toList(),
      showMessages: showMessages,
    );
  }

  Future<List<MedallaUsuario>?> getMedallasUsuario(String? userId,
      {bool showMessages = false}) async {
    // Si userId es null, retornar null o una lista vacía
    if (userId == null) return null;

    try {
      return get<List<MedallaUsuario>>(
        '/users/$userId/medallas',
        parser: (data) => (data as List)
            .map(
                (json) => MedallaUsuario.fromJson(json as Map<String, dynamic>))
            .toList(),
        showMessages: showMessages,
      );
    } catch (e) {
      return []; // También puedes retornar una lista vacía `return [];`
    }
  }

  Future<void> resetPendingMedallas(String userId,
      {bool showMessages = false}) async {
    await get('/users/$userId/medallas/reset-pending',
        showMessages: showMessages);
  }

  Future<void> subirAccionWeb({
    required String userId,
    required String tipo,
    required Uint8List imageBytes,
    double? latitude,
    double? longitude,
    bool showMessages = false,
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

    try {
      // Crear un FormData para enviar la imagen como bytes
      FormData formData = FormData.fromMap({
        'imagen': MultipartFile.fromBytes(
          imageBytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType.parse('image/jpeg'),
        ),
        'tipo_accion': tipoAccion,
        if (latitude != null) 'latitud': latitude,
        if (longitude != null) 'longitud': longitude,
      });

      // Realizar la solicitud POST
      final response = await _dio.post(
        '/users/$userId/actions',
        data: formData,
      );

      // Procesar la respuesta
      _processResponse(response, null, showMessages);
    } on DioException catch (e) {
      throw _handleError(e, showMessages);
    }
  }

  Exception _handleError(DioException e, bool showMessages) {
    String errorMessage;
    String errorCode;

    if (e.response != null && e.response!.data != null) {
      try {
        // Intentamos parsear la respuesta como ApiResponse
        final apiResponse = ApiResponse<dynamic>.fromJson(
          e.response!.data,
          (data) => data,
        );
        errorMessage = apiResponse.errorMessage;
        errorCode = apiResponse.code;
      } catch (_) {
        // Si no se puede parsear, usamos el código de estado HTTP
        errorCode = e.response!.statusCode.toString();
        errorMessage = _getErrorMessageFromStatusCode(e.response!.statusCode);
      }
    } else {
      // Si no hay respuesta, determinamos el tipo de error
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorCode = ApiCodes.codeServiceUnavailable;
          errorMessage = "Error de conexión";
          break;
        case DioExceptionType.sendTimeout:
          errorCode = ApiCodes.codeServiceUnavailable;
          errorMessage = "Error de tiempo de espera en la conexión";
          break;
        case DioExceptionType.receiveTimeout:
          errorCode = ApiCodes.codeServiceUnavailable;
          errorMessage = "Error de tiempo de espera en la conexión";
          break;
        case DioExceptionType.cancel:
          errorCode = ApiCodes.codeServiceUnavailable;
          errorMessage = "Solicitud cancelada";
          break;
        default:
          errorCode = ApiCodes.codeInternalServerError;
          errorMessage = "Error de conexión al servidor";
          break;
      }
    }

    // Mostrar notificación si está habilitado
    if (showMessages && _context != null) {
      notificationService.showError(_context!, errorMessage);
    }

    return Exception(errorMessage);
  }

  String _getErrorMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiCodes.getMessageForCode(ApiCodes.codeBadRequest);
      case 401:
        return ApiCodes.getMessageForCode(ApiCodes.codeUnauthorized);
      case 403:
        return ApiCodes.getMessageForCode(ApiCodes.codeForbidden);
      case 404:
        return ApiCodes.getMessageForCode(ApiCodes.codeNotFound);
      case 405:
        return ApiCodes.getMessageForCode(ApiCodes.codeMethodNotAllowed);
      case 409:
        return ApiCodes.getMessageForCode(ApiCodes.codeConflict);
      case 422:
        return ApiCodes.getMessageForCode(ApiCodes.codeValidationError);
      case 500:
        return ApiCodes.getMessageForCode(ApiCodes.codeInternalServerError);
      case 503:
        return ApiCodes.getMessageForCode(ApiCodes.codeServiceUnavailable);
      default:
        return "Error desconocido";
    }
  }
}
