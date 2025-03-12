import 'package:flutter/foundation.dart';
import '../models/user_action.dart';
import '../services/api_service.dart';

class AccionesProvider with ChangeNotifier {
  final ApiService _apiService;
  List<UserAction> _acciones = [];
  bool _isLoading = false;
  String? _error;

  AccionesProvider(this._apiService);

  List<UserAction> get acciones => _acciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAcciones(String userId, {bool showMessages = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/users/$userId/actions',
        parser: (data) =>
            (data as List).map((json) => UserAction.fromJson(json)).toList(),
        showMessages: showMessages,
      );
      _acciones = response;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarAccion(String accionId,
      {bool showMessages = false}) async {
    try {
      await _apiService.delete(
        '/actions/$accionId',
        showMessages: showMessages,
      );
      // Actualizar la lista local después de una eliminación exitosa
      _acciones.removeWhere((accion) => accion.id == accionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> subirAccion({
    required String userId,
    required String tipo,
    required String imagePath,
    double? latitude,
    double? longitude,
    bool showMessages = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.subirAccion(
        userId: userId,
        tipo: tipo,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        showMessages: showMessages,
      );

      // Recargar la lista de acciones después de subir una nueva
      await fetchAcciones(userId, showMessages: showMessages);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar el error para manejarlo en la UI
    }
  }
}
