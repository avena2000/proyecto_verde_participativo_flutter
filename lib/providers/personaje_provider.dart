import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PersonajeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String _cabello = 'default';
  String _vestimenta = 'default';
  String _barba = '0';
  String _detalleFacial = '0';
  String _detalleAdicional = '0';

  String get cabello => _cabello;
  String get vestimenta => _vestimenta;
  String get barba => _barba;
  String get detalleFacial => _detalleFacial;
  String get detalleAdicional => _detalleAdicional;

  // Cargar datos desde SharedPreferences
  Future<void> cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    _cabello = prefs.getString('cabello') ?? 'default';
    _vestimenta = prefs.getString('vestimenta') ?? 'default';
    _barba = prefs.getString('barba') ?? '0';
    _detalleFacial = prefs.getString('detalleFacial') ?? '0';
    _detalleAdicional = prefs.getString('detalleAdicional') ?? '0';
    notifyListeners();
  }

  // Actualizar todos los accesorios a la vez
  Future<void> actualizarAccesorios({
    required String cabello,
    required String vestimenta,
    required String barba,
    required String detalleFacial,
    required String detalleAdicional,
  }) async {
    _cabello = cabello;
    _vestimenta = vestimenta;
    _barba = barba;
    _detalleFacial = detalleFacial;
    _detalleAdicional = detalleAdicional;

    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cabello', cabello);
    await prefs.setString('vestimenta', vestimenta);
    await prefs.setString('barba', barba);
    await prefs.setString('detalleFacial', detalleFacial);
    await prefs.setString('detalleAdicional', detalleAdicional);

    // Actualizar en el backend
    try {
      final userId = prefs.getString('userId');
      if (userId != null) {
        await _apiService.put('/users/$userId/profile', data: {
          'cabello': cabello,
          'vestimenta': vestimenta,
          'barba': barba == 'default' || barba == '' ? '0' : barba,
          'detalle_facial': detalleFacial == 'default' || detalleFacial == '' ? '0' : detalleFacial,
          'detalle_adicional': detalleAdicional == 'default' || detalleAdicional == '' ? '0' : detalleAdicional,

        });
      }
    } catch (e) {
      debugPrint('Error al actualizar el perfil en el backend: $e');
    }

    notifyListeners();
  }

  Future<void> _actualizarBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        await _apiService.put('/users/$userId/profile', data: {
          'cabello': _cabello,
          'vestimenta': _vestimenta,
          'barba': _barba == 'default' ? '0' : _barba,
          'detalle_facial': _detalleFacial == 'default' ? '0' : _detalleFacial,
          'detalle_adicional': _detalleAdicional == 'default' ? '0' : _detalleAdicional,
        });
      }
    } catch (e) {
      debugPrint('Error al actualizar el perfil en el backend: $e');
    }
  }

  Future<void> setCabello(String value) async {
    _cabello = value;
    await _guardarLocal('cabello', value);
    await _actualizarBackend();
    notifyListeners();
  }

  Future<void> setVestimenta(String value) async {
    _vestimenta = value;
    await _guardarLocal('vestimenta', value);
    await _actualizarBackend();
    notifyListeners();
  }

  Future<void> setBarba(String value) async {
    _barba = value;
    await _guardarLocal('barba', value);
    await _actualizarBackend();
    notifyListeners();
  }

  Future<void> setDetalleFacial(String value) async {
    _detalleFacial = value;
    await _guardarLocal('detalleFacial', value);
    await _actualizarBackend();
    notifyListeners();
  }

  Future<void> setDetalleAdicional(String value) async {
    _detalleAdicional = value;
    await _guardarLocal('detalleAdicional', value);
    await _actualizarBackend();
    notifyListeners();
  }

  Future<void> _guardarLocal(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
} 