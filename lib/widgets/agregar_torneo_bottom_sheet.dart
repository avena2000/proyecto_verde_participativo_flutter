import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/models/torneo.dart';
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
  bool _isLoading = false;
  Torneo? _torneo;
  String? _ubicacionSeleccionada;
  bool _isTorneoEncontrado = false;

  @override
  void initState() {
    super.initState();
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

  void _agregarDireccion(DireccionGesto direccion) {
    if (_secuencia.length >= 5) return;
    HapticFeedback.vibrate();

    setState(() {
      _secuencia.add(direccion);

      // Si la secuencia llega a 5, buscar la información del torneo
      if (_secuencia.length == 5) {
        _buscarInfoTorneo();
      }
    });
  }

  void _limpiarSecuencia() {
    HapticFeedback.vibrate();
    setState(() {
      _secuencia.clear();
      _torneo = null;
      _ubicacionSeleccionada = null;
      _isTorneoEncontrado = false;
    });
  }

  String _obtenerCodigoTorneo() {
    return _secuencia.map((direccion) {
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
  }

  Future<void> _buscarInfoTorneo() async {
    setState(() => _isLoading = true);

    try {
      final codigoTorneo = _obtenerCodigoTorneo();
      ApiService().setContext(context);
      final response = await ApiService().get('/torneos/code/$codigoTorneo',
          parser: (data) => Torneo.fromJson(data), showMessages: true);

      setState(() {
        _torneo = response;
        _isLoading = false;
        _isTorneoEncontrado = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          notificationService.showError(context, "El torneo no existe");
        } else {
          notificationService.showError(context, "Error al buscar el torneo");
        }
      }
    }
  }

  Future<void> inscribirseATorneo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final codigoTorneo = _obtenerCodigoTorneo();

    // Verificar si es versus y se ha seleccionado ubicación
    if (_torneo?.modalidad == 'versus' && _ubicacionSeleccionada == null) {
      notificationService.showError(
          context, "Debes seleccionar un equipo antes de inscribirte");
      return;
    }

    if (userId != null) {
      try {
        setState(() => _isLoading = true);

        Map<String, dynamic> data = {
          'user_id': userId,
        };

        // Establecer el parámetro 'team' según modalidad y equipo seleccionado
        if (_torneo?.modalidad.toLowerCase() == 'versus') {
          // Para modalidad 'versus', true para equipo A, false para equipo B
          data['team'] = _ubicacionSeleccionada == 'A';
        } else {
          // Para modalidad individual siempre es true
          data['team'] = true;
        }

        await ApiService().post('/torneos/inscribir/$codigoTorneo',
            data: data, parser: (data) => data, showMessages: true);

        await prefs.setString('torneo_modalidad', _torneo?.modalidad ?? '');
        if (_torneo?.ubicacionAproximada != null) {
          if (_ubicacionSeleccionada == 'A' ||
              _torneo?.modalidad.toLowerCase() != 'versus') {
            await prefs.setDouble(
                'torneo_latitud', _torneo?.ubicacionALatitud ?? 0.0);
            await prefs.setDouble(
                'torneo_longitud', _torneo?.ubicacionALongitud ?? 0.0);
          } else {
            await prefs.setDouble(
                'torneo_latitud', _torneo?.ubicacionBLatitud ?? 0.0);
            await prefs.setDouble(
                'torneo_longitud', _torneo?.ubicacionBLongitud ?? 0.0);
          }
          await prefs.setInt('torneo_metros', _torneo?.metrosAprox ?? 0);
          await prefs.setBool('torneo_inscrito', true);
        }

        setState(() => _isLoading = false);
        notificationService.showSuccess(
            context, "Te has inscrito al torneo correctamente");
        Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        if (e is DioException) {
          if (e.response?.statusCode == 400) {
            notificationService.showError(
                context, "Ya estás inscrito en este torneo");
          } else {
            notificationService.showError(
                context, "Error al inscribirse al torneo");
          }
        }
      }
    }
  }

  bool _puedeInscribirse() {
    if (_torneo == null) return false;

    // Verificar si el torneo no ha finalizado
    final bool torneoNoFinalizado = !_torneo!.finalizado;

    // En caso de ser versus, verificar que se haya seleccionado ubicación
    final bool requiereUbicacion = _torneo!.modalidad.toLowerCase() == 'versus';
    final bool ubicacionSeleccionada = _ubicacionSeleccionada != null;

    return torneoNoFinalizado && (!requiereUbicacion || ubicacionSeleccionada);
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

          // Mostrar información del torneo cuando se ha encontrado
          if (_isLoading) const CircularProgressIndicator(color: Colors.white),

          if (_isTorneoEncontrado && _torneo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _torneo!.nombre,
                    style: const TextStyle(
                      fontFamily: 'YesevaOne',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${_torneo!.finalizado ? 'Finalizado' : 'Activo'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modalidad: ${_torneo!.modalidad}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha inicio: ${_torneo!.fechaInicio.day}/${_torneo!.fechaInicio.month}/${_torneo!.fechaInicio.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha fin: ${_torneo!.fechaFin.day}/${_torneo!.fechaFin.month}/${_torneo!.fechaFin.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),

                  // Si es modalidad versus, mostrar botones para elegir ubicación
                  if (_torneo?.modalidad.toLowerCase() == 'versus' &&
                      !_torneo!.finalizado)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Debes seleccionar obligatoriamente un equipo:',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _ubicacionSeleccionada = 'A');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ubicacionSeleccionada == 'A'
                                      ? Colors.amber.shade800
                                      : Colors.grey.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        _torneo!.nombreUbicacionA,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _ubicacionSeleccionada = 'B');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ubicacionSeleccionada == 'B'
                                      ? Colors.amber.shade800
                                      : Colors.grey.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        _torneo!.nombreUbicacionB ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                  // En caso de torneo finalizado o no versus, mostrar un mensaje informativo
                  if (_torneo!.finalizado)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este torneo ya ha finalizado',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_torneo!.modalidad.toLowerCase() != 'versus')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Puedes inscribirte directamente a este torneo individual',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (!_isTorneoEncontrado || _torneo == null) ...[
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
                    onPressed: _secuencia.isNotEmpty ? _limpiarSecuencia : null,
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
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed:
                  (_isTorneoEncontrado && _puedeInscribirse() && !_isLoading)
                      ? inscribirseATorneo
                      : (_secuencia.length == 5 &&
                              !_isTorneoEncontrado &&
                              !_isLoading)
                          ? _buscarInfoTorneo
                          : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isTorneoEncontrado ? 'Inscribirme al torneo' : 'Buscar torneo',
                style: const TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_isTorneoEncontrado)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: _limpiarSecuencia,
                child: const Text(
                  'Ingresar otro código',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
              onTap: () {
                Navigator.pop(context);
                showCustomBottomSheet(
                  context,
                  (scrollController) => CrearTorneoBottomSheet(
                      scrollController: scrollController),
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

  Widget _buildDirectionButton(DireccionGesto direccion, IconData iconData) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed:
            _secuencia.length < 5 ? () => _agregarDireccion(direccion) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(iconData, color: Colors.white),
      ),
    );
  }
}
