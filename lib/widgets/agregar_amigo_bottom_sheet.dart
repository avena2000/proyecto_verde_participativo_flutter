import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

enum DireccionGesto {
  arriba,
  abajo,
  izquierda,
  derecha,
}

class AgregarAmigoBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const AgregarAmigoBottomSheet({
    super.key,
    required this.scrollController,
  });

  @override
  State<AgregarAmigoBottomSheet> createState() =>
      _AgregarAmigoBottomSheetState();
}

class _AgregarAmigoBottomSheetState extends State<AgregarAmigoBottomSheet> {
  final List<DireccionGesto> _secuencia = [];
  final notificationService = NotificationService();
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

  void _agregarDireccion(DireccionGesto direccion) {
    if (_secuencia.length >= 5) return;
    HapticFeedback.vibrate();
    setState(() => _secuencia.add(direccion));
  }

  void _limpiarSecuencia() {
    HapticFeedback.vibrate();
    setState(() => _secuencia.clear());
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
        ApiService apiService = ApiService();
        apiService.setContext(context);
        await apiService.post('/users/$userId/friends/add',
            data: {
              'friend_id_request': secuenciaString,
            },
            showMessages: true,
            parser: (data) => data);
        notificationService.showSuccess(
            context, "Solicitud enviada correctamente");
        Navigator.pop(context, _secuencia);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SafeArea(
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 21),
              Center(
                child: Text(
                  'Agregar Amigo',
                  style: TextStyle(
                    fontFamily: 'YesevaOne',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_friendId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tu código:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
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
                    children: _friendId?.split('-').map((direccion) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(AppColors.primaryGreen),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: _obtenerIconoDesdeString(direccion),
                            ),
                          );
                        }).toList() ??
                        [],
                  ),
                ),
              ],
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
                          color: Color(AppColors.primaryGreen),
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

              // Botones direccionales para todos los dispositivos
              Text(
                'Usa estos botones para agregar direcciones',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 60),
                  _buildDirectionButton(
                      DireccionGesto.arriba, Icons.arrow_upward),
                  const SizedBox(width: 60),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDirectionButton(
                      DireccionGesto.izquierda, Icons.arrow_back),
                  const SizedBox(width: 0),
                  // Botón de basura en el centro
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed:
                          _secuencia.isNotEmpty ? _limpiarSecuencia : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 0),
                  _buildDirectionButton(
                      DireccionGesto.derecha, Icons.arrow_forward),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 60),
                  _buildDirectionButton(
                      DireccionGesto.abajo, Icons.arrow_downward),
                  const SizedBox(width: 60),
                ],
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
                    'Añadir Amigo',
                    style: TextStyle(
                      fontFamily: 'YesevaOne',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildDirectionButton(DireccionGesto direccion, IconData iconData) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed:
            _secuencia.length < 5 ? () => _agregarDireccion(direccion) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(AppColors.primaryGreen),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(iconData, color: Colors.white),
      ),
    );
  }
}
