import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto_verde_participativo/constants/colors.dart';
import 'package:proyecto_verde_participativo/models/torneo.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:intl/intl.dart';

class TorneoInfoBottomSheet extends StatefulWidget {
  final String torneoId;
  final Function onTorneoAbandonado;
  final ScrollController? scrollController;

  const TorneoInfoBottomSheet({
    super.key,
    required this.torneoId,
    required this.onTorneoAbandonado,
    this.scrollController,
  });

  @override
  State<TorneoInfoBottomSheet> createState() => _TorneoInfoBottomSheetState();
}

class _TorneoInfoBottomSheetState extends State<TorneoInfoBottomSheet>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  bool _isLoading = true;
  Torneo? _torneo;
  bool? _esEquipoA;
  LatLng? _currentPosition;
  final ScrollController _scrollController = ScrollController();
  late final _animatedMapController = AnimatedMapController(vsync: this);
  double _currentZoom = 15.0;

  // Formato para mostrar la fecha y hora
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _scrollController;

  @override
  void initState() {
    super.initState();
    _cargarDatosTorneo();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // Solo eliminar el controlador si es interno
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _animatedMapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar los permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Obtener la posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  // Calcula el zoom basado en el radio en metros
  double _calcularZoom(int metrosAprox) {
    // Fórmula aproximada para determinar el nivel de zoom según la distancia
    // Cuanto más grande es el radio, menor debe ser el zoom para que se vea todo el área
    if (metrosAprox <= 200) return 16.0;
    if (metrosAprox <= 500) return 15.0;
    if (metrosAprox <= 1000) return 14.0;
    if (metrosAprox <= 2000) return 13.0;
    return 12.0; // Para radios mayores a 2000m
  }

  Future<void> _cargarDatosTorneo() async {
    try {
      setState(() => _isLoading = true);

      // Obtener datos del torneo
      final torneo = await _apiService.get(
        '/torneos/${widget.torneoId}',
        parser: (data) => Torneo.fromJson(data),
      );

      // Obtener información sobre el equipo del usuario en el torneo
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final equipoInfo = await _apiService.get(
          '/torneos/${widget.torneoId}/usuario/$userId/equipo',
          parser: (data) => data['equipo'] as bool,
        );

        setState(() {
          _torneo = torneo;
          _esEquipoA = equipoInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      notificationService.showError(
          context, "No se pudo cargar la información del torneo");
    }
  }

  Future<void> _mostrarConfirmacionSalida() async {
    HapticFeedback.mediumImpact();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text(
            'Si abandonas el torneo, tu equipo perderá los puntos que has aportado. Esta acción no se puede deshacer.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Abandonar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _abandonarTorneo();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _abandonarTorneo() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        _apiService.setContext(context);
        await _apiService.delete(
          '/torneos/${widget.torneoId}/usuario/$userId',
          showMessages: true,
        );

        notificationService.showSuccess(
            context, "Has abandonado el torneo exitosamente");

        // Actualizar SharedPreferences
        await prefs.setString('torneo', '');

        // Notificar que el torneo fue abandonado
        widget.onTorneoAbandonado();

        // Cerrar el bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      notificationService.showError(
          context, "No se pudo abandonar el torneo. Inténtalo de nuevo.");
    }
  }

  // Función para acercar el zoom con animación
  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
      _animatedMapController.animatedZoomIn(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  // Función para alejar el zoom con animación
  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
      _animatedMapController.animatedZoomOut(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
      child: SingleChildScrollView(
        controller: _effectiveScrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Información del Torneo',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else if (_torneo != null)
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
                      'Fecha inicio: ${_dateFormat.format(_torneo!.fechaInicio.toLocal())} a las ${_timeFormat.format(_torneo!.fechaInicio.toLocal())}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha fin: ${_dateFormat.format(_torneo!.fechaFin.toLocal())} a las ${_timeFormat.format(_torneo!.fechaFin.toLocal())}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),

                    // Si es modalidad versus, mostrar el equipo del usuario
                    if (_torneo?.modalidad.toLowerCase() == 'versus' &&
                        _esEquipoA != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.group, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Perteneces al equipo: ${_esEquipoA! ? _torneo!.nombreUbicacionA : _torneo!.nombreUbicacionB ?? 'Ubicación B'}',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (!_isLoading && _torneo != null)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación válida para el torneo${_torneo?.modalidad.toLowerCase() == 'versus' && _esEquipoA != null ? (_esEquipoA! ? ': ${_torneo!.nombreUbicacionA}' : ': ${_torneo!.nombreUbicacionB ?? 'Ubicación B'}') : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Mostrar el nombre de la ubicación correspondiente según el equipo
                    Text(
                      _torneo!.modalidad.toLowerCase() == 'versus' &&
                              _esEquipoA != null &&
                              !_esEquipoA!
                          ? _torneo!.nombreUbicacionB ?? 'Ubicación B'
                          : _torneo!.nombreUbicacionA,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Contenedor del mapa con botones de zoom superpuestos
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: FlutterMap(
                              mapController:
                                  _animatedMapController.mapController,
                              options: MapOptions(
                                initialCenter: LatLng(
                                  // Usar la ubicación correspondiente al equipo del usuario, con manejo de nulos
                                  _torneo!.modalidad.toLowerCase() ==
                                              'versus' &&
                                          _esEquipoA != null &&
                                          !_esEquipoA! &&
                                          _torneo!.ubicacionBLatitud != null
                                      ? _torneo!.ubicacionBLatitud!
                                      : _torneo!.ubicacionALatitud,
                                  _torneo!.modalidad.toLowerCase() ==
                                              'versus' &&
                                          _esEquipoA != null &&
                                          !_esEquipoA! &&
                                          _torneo!.ubicacionBLongitud != null
                                      ? _torneo!.ubicacionBLongitud!
                                      : _torneo!.ubicacionALongitud,
                                ),
                                // Ajustar el zoom según el radio en metros
                                initialZoom: _torneo!.ubicacionAproximada &&
                                        _torneo!.metrosAprox != null
                                    ? _calcularZoom(_torneo!.metrosAprox!)
                                    : 15,
                                onMapReady: () {
                                  // Guardar el zoom inicial calculado
                                  setState(() {
                                    _currentZoom = _torneo!
                                                .ubicacionAproximada &&
                                            _torneo!.metrosAprox != null
                                        ? _calcularZoom(_torneo!.metrosAprox!)
                                        : 15;
                                  });
                                },
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.vive.app',
                                  tileProvider:
                                      CancellableNetworkTileProvider(),
                                ),
                                // Agregar círculo para mostrar el radio del torneo
                                if (_torneo!.ubicacionAproximada &&
                                    _torneo!.metrosAprox != null)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: LatLng(
                                          // Usar la ubicación correspondiente al equipo del usuario
                                          _torneo!.modalidad.toLowerCase() ==
                                                      'versus' &&
                                                  _esEquipoA != null &&
                                                  !_esEquipoA! &&
                                                  _torneo!.ubicacionBLatitud !=
                                                      null
                                              ? _torneo!.ubicacionBLatitud!
                                              : _torneo!.ubicacionALatitud,
                                          _torneo!.modalidad.toLowerCase() ==
                                                      'versus' &&
                                                  _esEquipoA != null &&
                                                  !_esEquipoA! &&
                                                  _torneo!.ubicacionBLongitud !=
                                                      null
                                              ? _torneo!.ubicacionBLongitud!
                                              : _torneo!.ubicacionALongitud,
                                        ),
                                        radius:
                                            _torneo!.metrosAprox!.toDouble(),
                                        useRadiusInMeter: true,
                                        color: Color(AppColors.primaryGreen)
                                            .withOpacity(0.2),
                                        borderColor:
                                            Color(AppColors.primaryGreen)
                                                .withOpacity(0.8),
                                        borderStrokeWidth: 2.0,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    // Marcador para la ubicación del torneo
                                    Marker(
                                      point: LatLng(
                                        // Usar la ubicación correspondiente al equipo del usuario
                                        _torneo!.modalidad.toLowerCase() ==
                                                    'versus' &&
                                                _esEquipoA != null &&
                                                !_esEquipoA! &&
                                                _torneo!.ubicacionBLatitud !=
                                                    null
                                            ? _torneo!.ubicacionBLatitud!
                                            : _torneo!.ubicacionALatitud,
                                        _torneo!.modalidad.toLowerCase() ==
                                                    'versus' &&
                                                _esEquipoA != null &&
                                                !_esEquipoA! &&
                                                _torneo!.ubicacionBLongitud !=
                                                    null
                                            ? _torneo!.ubicacionBLongitud!
                                            : _torneo!.ubicacionALongitud,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(AppColors.primaryGreen)
                                              .withOpacity(0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: Color(AppColors.primaryGreen),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    // Marcador para la ubicación actual del usuario
                                    if (_currentPosition != null)
                                      Marker(
                                        point: _currentPosition!,
                                        width: 40,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.my_location,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Botones de zoom superpuestos en el mapa
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add,
                                      color: Colors.black87),
                                  onPressed: _zoomIn,
                                  tooltip: 'Acercar',
                                  iconSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove,
                                      color: Colors.black87),
                                  onPressed: _zoomOut,
                                  tooltip: 'Alejar',
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Mostrar información sobre el radio del torneo si está habilitado
                    if (_torneo!.ubicacionAproximada &&
                        _torneo!.metrosAprox != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                Color(AppColors.primaryGreen).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(AppColors.primaryGreen)
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.radar,
                                color: Color(AppColors.primaryGreen),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Radio de acción: ${_torneo!.metrosAprox} metros',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Información sobre tu ubicación actual
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu ubicación actual',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (!_isLoading && _torneo != null && !_torneo!.finalizado)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _mostrarConfirmacionSalida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Abandonar torneo',
                    style: TextStyle(
                      fontFamily: 'YesevaOne',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
