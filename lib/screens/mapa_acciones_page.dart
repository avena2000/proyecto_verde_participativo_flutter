import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:proyecto_verde_participativo/models/user_action.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/constants/colors.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:proyecto_verde_participativo/utils/page_transitions.dart';
import 'package:proyecto_verde_participativo/widgets/custom_notification.dart';
import 'package:proyecto_verde_participativo/widgets/fullscreen_image_gallery.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:proyecto_verde_participativo/widgets/action_user_personaje.dart';

class MapaAccionesPage extends StatefulWidget {
  const MapaAccionesPage({super.key});

  @override
  State<MapaAccionesPage> createState() => _MapaAccionesPageState();
}

class _MapaAccionesPageState extends State<MapaAccionesPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final _animatedMapController = AnimatedMapController(vsync: this);
  final notificationService = NotificationService();

  List<Marker> _markers = [];
  bool _isLoading = true;
  LatLng? _currentLocation;
  Map<String, List<UserAction>> _groupedActions = {};
  int _currentMarkerIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullScreenMode();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setFullScreenMode();
    }
  }

  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _cargarAcciones();
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      // Si no podemos obtener la ubicación, cargamos las acciones con ubicación por defecto
      _cargarAcciones();
    }
  }

  Future<void> _cargarAcciones() async {
    try {
      final acciones = await _apiService.get(
        '/actions',
        parser: (data) =>
            (data as List).map((item) => UserAction.fromJson(item)).toList(),
      );

      _groupedActions.clear();
      // Agrupar acciones por proximidad
      for (var accion in acciones) {
        bool added = false;
        for (var key in _groupedActions.keys) {
          var firstAction = _groupedActions[key]!.first;
          if (_isNearby(LatLng(firstAction.latitud, firstAction.longitud),
              LatLng(accion.latitud, accion.longitud))) {
            _groupedActions[key]!.add(accion);
            added = true;
            break;
          }
        }
        if (!added) {
          String key = '${accion.latitud}_${accion.longitud}';
          _groupedActions[key] = [accion];
        }
      }

      setState(() {
        _markers = _groupedActions.entries.map((entry) {
          var actions = entry.value;
          var firstAction = actions.first;
          return Marker(
            point: LatLng(firstAction.latitud, firstAction.longitud),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => actions.length == 1
                  ? _mostrarImagenCompleta(actions, 0)
                  : _mostrarListaAcciones(actions),
              child: Container(
                decoration: BoxDecoration(
                  color: actions.length > 1
                      ? Colors.purple
                      : _getMarkerColor(firstAction.tipoAccion),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: actions.length > 1
                      ? Text(
                          actions.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          _getMarkerIcon(firstAction.tipoAccion),
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          );
        }).toList();
        _isLoading = false;
        if (_markers.isNotEmpty) {
          _currentMarkerIndex = 0;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      notificationService.showNotification(
        context,
        message: 'Error al cargar las acciones',
        type: NotificationType.error,
      );
    }
  }

  bool _isNearby(LatLng point1, LatLng point2) {
    const double threshold = 0.001; // Aproximadamente 100 metros
    return (point1.latitude - point2.latitude).abs() < threshold &&
        (point1.longitude - point2.longitude).abs() < threshold;
  }

  void _mostrarImagenCompleta(List<UserAction> acciones, int index) {
    Navigator.of(context).push(BottomSheetTransition(
      page: FullscreenImageGallery(
        acciones: acciones,
        initialIndex: index,
      ),
    ));
  }

  void _mostrarListaAcciones(List<UserAction> acciones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Tamaño inicial (70% de la pantalla)
        minChildSize: 0.3, // Mínimo (30% de la pantalla)
        maxChildSize: 0.9, // Máximo (90% de la pantalla)
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Color(AppColors.darkGreen),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(27),
                topRight: Radius.circular(27),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Acciones por aquí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'YesevaOne',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller:
                          scrollController, // Conecta con `DraggableScrollableSheet`
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: acciones.length,
                      itemBuilder: (context, index) {
                        final accion = acciones[index];
                        return GestureDetector(
                          onTap: () => _mostrarImagenCompleta(acciones, index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: CachedNetworkImage(
                                    imageRenderMethodForWeb:
                                        ImageRenderMethodForWeb.HttpGet,
                                    imageUrl: accion.foto,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Acción de ${accion.tipoAccion}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'YesevaOne',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Color(
                                                      AppColors.primaryGreen),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    "${accion.lugar}, ${accion.ciudad}",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                          ],
                                        ),
                                      ),
                                      ActionUserPersonaje(
                                        userId: accion.userId,
                                        size: 60,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMarkerColor(String tipoAccion) {
    switch (tipoAccion.toLowerCase()) {
      case 'ayuda':
        return Colors.green;
      case 'descubrimiento':
        return Colors.blue;
      case 'alerta':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  IconData _getMarkerIcon(String tipoAccion) {
    switch (tipoAccion.toLowerCase()) {
      case 'ayuda':
        return Icons.volunteer_activism;
      case 'descubrimiento':
        return Icons.explore;
      case 'alerta':
        return Icons.warning_amber;
      default:
        return Icons.place;
    }
  }

  void _navigateToNextMarker() {
    if (_markers.isEmpty) return;
    setState(() {
      _currentMarkerIndex = (_currentMarkerIndex + 1) % _markers.length;
    });
    _animateToCurrentMarker();
  }

  void _navigateToPreviousMarker() {
    if (_markers.isEmpty) return;
    setState(() {
      _currentMarkerIndex = _currentMarkerIndex <= 0
          ? _markers.length - 1
          : _currentMarkerIndex - 1;
    });
    _animateToCurrentMarker();
  }

  void _animateToCurrentMarker() {
    if (_currentMarkerIndex >= 0 && _currentMarkerIndex < _markers.length) {
      final marker = _markers[_currentMarkerIndex];
      _animatedMapController.centerOnPoint(
        marker.point,
        zoom: 16,
      );

      // Mostrar un snackbar con información de la acción
      final actions = _groupedActions.values.elementAt(_currentMarkerIndex);
      final count = actions.length;
      final type = actions.first.tipoAccion;

      notificationService.showNotification(
        context,
        message: count > 1
            ? '$count acciones en esta ubicación'
            : 'Acción de tipo $type',
        type: NotificationType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Color(AppColors.darkGreen),
          elevation: 0,
          title: const Text(
            'Mapa de Acciones',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'YesevaOne',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(AppColors.primaryGreen),
                ),
              )
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _animatedMapController.mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation ??
                            const LatLng(19.4326, -99.1332), // Ciudad de México
                        initialZoom: 16,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.drag |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.vive.app',
                          tileProvider: CancellableNetworkTileProvider(),
                        ),
                        MarkerLayer(
                          markers: [
                            if (_currentLocation != null)
                              Marker(
                                point: _currentLocation!,
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
                            ..._markers,
                          ],
                        ),
                      ],
                    ),
                    if (_currentLocation != null)
                      Positioned(
                        bottom: 64,
                        right: 16,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FloatingActionButton(
                                heroTag: 'mapa_acciones_center_location',
                                backgroundColor: Color(AppColors.darkGreen),
                                onPressed: () {
                                  _animatedMapController.centerOnPoint(
                                    _currentLocation!,
                                    zoom: 16,
                                  );
                                },
                                child: const Icon(Icons.my_location,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  FloatingActionButton(
                                    heroTag: 'mapa_acciones_prev_marker',
                                    backgroundColor: Color(AppColors.darkGreen),
                                    onPressed: () {
                                      _navigateToPreviousMarker();
                                    },
                                    child: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  FloatingActionButton(
                                    heroTag: 'mapa_acciones_next_marker',
                                    backgroundColor: Color(AppColors.darkGreen),
                                    onPressed: () {
                                      _navigateToNextMarker();
                                    },
                                    child: const Icon(Icons.arrow_forward,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ]),
                      )
                  ],
                ),
              ),
      ),
    );
  }
}
