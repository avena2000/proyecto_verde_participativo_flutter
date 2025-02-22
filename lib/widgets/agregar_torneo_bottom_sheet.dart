import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../utils/functions.dart';
import 'crear_torneo_bottom_sheet.dart';

enum DireccionGesto {
  arriba,
  abajo,
  izquierda,
  derecha,
}

class AgregarTorneoBottomSheet extends StatefulWidget {
  const AgregarTorneoBottomSheet({
    super.key,
  });

  @override
  State<AgregarTorneoBottomSheet> createState() =>
      _AgregarTorneoBottomSheetState();
}

class _AgregarTorneoBottomSheetState extends State<AgregarTorneoBottomSheet> {
  final List<DireccionGesto> _secuencia = [];
  final notificationService = NotificationService();
  Offset? _startPosition;
  String? _friendId;

  @override
  void initState() {
    super.initState();
    _cargarFriendId();
  }

  Future<void> _cargarFriendId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _friendId = prefs.getString('friendId');
    });
  }

  Icon _obtenerIcono(DireccionGesto direccion) {
    switch (direccion) {
      case DireccionGesto.arriba:
        return const Icon(Icons.north, color: Colors.white, size: 24);
      case DireccionGesto.abajo:
        return const Icon(Icons.south, color: Colors.white, size: 24);
      case DireccionGesto.izquierda:
        return const Icon(Icons.west, color: Colors.white, size: 24);
      case DireccionGesto.derecha:
        return const Icon(Icons.east, color: Colors.white, size: 24);
    }
  }

  Icon _obtenerIconoDesdeString(String direccion) {
    switch (direccion) {
      case 'up':
        return const Icon(Icons.north, color: Colors.white, size: 24);
      case 'down':
        return const Icon(Icons.south, color: Colors.white, size: 24);
      case 'left':
        return const Icon(Icons.west, color: Colors.white, size: 24);
      case 'right':
        return const Icon(Icons.east, color: Colors.white, size: 24);
      default:
        return const Icon(Icons.question_mark, color: Colors.white, size: 24);
    }
  }

  void _procesarGesto(Offset delta) {
    if (_secuencia.length >= 5) return;
    HapticFeedback.vibrate();
    const sensibilidad = 50.0;
    if (delta.dx.abs() > delta.dy.abs()) {
      // Movimiento horizontal
      if (delta.dx > sensibilidad) {
        setState(() => _secuencia.add(DireccionGesto.derecha));
      } else if (delta.dx < -sensibilidad) {
        setState(() => _secuencia.add(DireccionGesto.izquierda));
      }
    } else {
      // Movimiento vertical
      if (delta.dy > sensibilidad) {
        setState(() => _secuencia.add(DireccionGesto.abajo));
      } else if (delta.dy < -sensibilidad) {
        setState(() => _secuencia.add(DireccionGesto.arriba));
      }
    }
  }

  Future<void> agregarAmigo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    String secuenciaString = _secuencia.map((direccion) {
      switch (direccion) {
        case DireccionGesto.arriba:
          return 'up';
        case DireccionGesto.abajo:
          return 'down';
        case DireccionGesto.izquierda:
          return 'left';
        case DireccionGesto.derecha:
          return 'right';
      }
    }).join('-');

    if (userId != null) {
      try {
        await ApiService().post('/users/$userId/friends/add',
            data: {
              'friend_id_request': secuenciaString,
            },
            parser: (data) => data);
        notificationService.showSuccess(
            context, "Amigo agregado correctamente");
        Navigator.pop(context, _secuencia);
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 404) {
            notificationService.showError(
                context, "El usuario que buscas no existe");
          } else if (e.response?.statusCode == 409) {
            notificationService.showError(
                context, "No te puedes agregar a ti mismo");
          } else if (e.response?.statusCode == 400) {
            notificationService.showError(
                context, "El usuario ya es tu amigo o está pendiente");
          } else {
            notificationService.showError(
                context, "Ocurrió un error al agregar amigo");
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Unirte a un torneo',
              style: TextStyle(
                fontFamily: 'YesevaOne',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                if (index < _secuencia.length) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _obtenerIcono(_secuencia[index]),
                    ),
                  );
                } else {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onPanStart: (details) {
              _startPosition = details.globalPosition;
            },
            onPanUpdate: (details) {
              if (_startPosition != null) {
                final delta = details.globalPosition - _startPosition!;
                if (delta.distance > 50) {
                  _procesarGesto(delta);
                  _startPosition = null;
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'Desliza en cualquier dirección\npara agregar una flecha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _secuencia.clear());
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _secuencia.length == 5
                  ? () {
                      agregarAmigo();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Unirme al torneo',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
              onTap: () {
                Navigator.pop(context, _secuencia);
                showCustomBottomSheet(
                  context,
                  (scrollController) => CrearTorneoBottomSheet(scrollController: scrollController),
                  canExpand: true,
                );
              },
              child: const Text(
                'Crear un torneo',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
