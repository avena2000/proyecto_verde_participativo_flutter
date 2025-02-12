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

  Future<void> fetchAcciones(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users/$userId/actions');
      final List<dynamic> actionsList = response;
      _acciones = actionsList.map((json) => UserAction.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> subirAccion({
    required String userId,
    required String tipo,
    required String imagePath,
    double? latitude,
    double? longitude,
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
      );

      // Recargar la lista de acciones después de subir una nueva
      await fetchAcciones(userId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-lanzar el error para manejarlo en la UI
    }
  }
}
