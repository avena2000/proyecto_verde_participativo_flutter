import 'package:flutter/material.dart';
import '../models/accion.dart';
import '../services/api_service.dart';

class AccionesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Accion> _acciones = [];
  bool _isLoading = false;
  String? _error;

  List<Accion> get acciones => _acciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarAcciones() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _acciones = await _apiService.getAcciones();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
      await cargarAcciones();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e; // Re-lanzar el error para manejarlo en la UI
    }
  }
} 