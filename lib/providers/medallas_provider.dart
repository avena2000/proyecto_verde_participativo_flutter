import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medalla.dart';
import '../services/api_service.dart';

class MedallasProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Medalla> _medallas = [];
  bool _isLoading = false;
  String? _error;

  List<Medalla> get medallas => _medallas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarMedallas(String userId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // Cargar todas las medallas disponibles
    final todasLasMedallas = await _apiService.getMedallas();
    final medallasUsuario = await _apiService.getMedallasUsuario(userId);

    // Obtener SharedPreferences para calcular progreso
    final prefs = await SharedPreferences.getInstance();

    // Procesar cada medalla y calcular su progreso
    List<Medalla> medallasDesbloqueadas = [];
    List<Medalla> medallasNoDesbloqueadas = [];

    for (var medalla in todasLasMedallas) {
      final medallasDesbloqueada =
          medallasUsuario.any((m) => m.idMedalla == medalla.id);
      final progreso = _calcularProgreso(
        medalla.requiereAmistades,
        medalla.requierePuntos,
        medalla.requiereAcciones,
        medalla.requiereTorneos,
        medalla.requiereVictoriaTorneos,
        medalla.numeroRequerido,
        prefs,
      );

      final nuevaMedalla = Medalla(
        id: medalla.id,
        nombre: medalla.nombre,
        descripcion: medalla.descripcion,
        dificultad: medalla.dificultad,
        requiereAmistades: medalla.requiereAmistades,
        requierePuntos: medalla.requierePuntos,
        requiereAcciones: medalla.requiereAcciones,
        requiereTorneos: medalla.requiereTorneos,
        requiereVictoriaTorneos: medalla.requiereVictoriaTorneos,
        numeroRequerido: medalla.numeroRequerido,
        desbloqueada: medallasDesbloqueada,
        progreso: progreso,
      );

      if (medallasDesbloqueada) {
        medallasDesbloqueadas.add(nuevaMedalla);
      } else {
        medallasNoDesbloqueadas.add(nuevaMedalla);
      }
    }

    // Ordenar las medallas desbloqueadas y no desbloqueadas por dificultad (de menos a más)
    medallasDesbloqueadas.sort((a, b) => a.dificultad.compareTo(b.dificultad));
    medallasNoDesbloqueadas.sort((a, b) => a.dificultad.compareTo(b.dificultad));

    // Combinar las dos listas, primero las desbloqueadas y luego las no desbloqueadas
    _medallas = [...medallasDesbloqueadas, ...medallasNoDesbloqueadas];

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}

  double _calcularProgreso(bool requiereAmistades, bool requierePuntos, bool requiereAcciones, bool requiereTorneos, bool requiereVictoriaTorneos, int numeroRequerido, SharedPreferences prefs) {
    double progreso = 0.0;

    if (requiereAmistades) {
      final valorActual = prefs.getInt('amigos') ?? 0;
      if (valorActual >= numeroRequerido) {
        progreso = 1;
      } else {
        progreso = valorActual / numeroRequerido;
      }
    }
    if (requierePuntos) {
      final valorActual = prefs.getInt('puntos') ?? 0;
      if (valorActual >= numeroRequerido) {
        progreso = 1;
      } else {
        progreso = valorActual / numeroRequerido;
      }
    }
    if (requiereAcciones) {
      final valorActual = prefs.getInt('acciones') ?? 0;
      if (valorActual >= numeroRequerido) {
        progreso = 1;
      } else {
        progreso = valorActual / numeroRequerido;
      }
    } 
    if (requiereTorneos) {
      final valorActual = prefs.getInt('torneos') ?? 0;
      if (valorActual >= numeroRequerido) {
        progreso = 1;
      } else {
        progreso = valorActual / numeroRequerido;
      }
    } 
    if (requiereVictoriaTorneos) {
      final valorActual = prefs.getInt('victoriaTorneos') ?? 0;
      if (valorActual >= numeroRequerido) {
        progreso = 1;
      } else {
        progreso = valorActual / numeroRequerido;
      }
    }

    return progreso;
  }
}
