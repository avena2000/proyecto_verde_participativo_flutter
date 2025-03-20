import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../models/torneo.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'dart:ui';

class AdminTorneoPage extends StatefulWidget {
  const AdminTorneoPage({
    super.key,
  });

  @override
  State<AdminTorneoPage> createState() => _AdminTorneoPageState();
}

class _AdminTorneoPageState extends State<AdminTorneoPage> {
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  Torneo? _torneo;
  bool _isLoading = true;
  String _userId = '';
  final List<DireccionGesto> _secuencia = [];

  @override
  void initState() {
    super.initState();
    _cargarTorneo();
  }

  Future<void> _cargarTorneo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId') ?? '';

      if (_userId == '') {
        notificationService.showError(context, "Error de autenticación");
        return;
      }

      final response = await _apiService.get(
        '/torneos/admin/$_userId',
        parser: (data) => Torneo.fromJson(data),
      );

      setState(() {
        _torneo = response;
        _isLoading = false;
      });
    } catch (e) {
      notificationService.showError(context, "Error al cargar el torneo");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _terminarTorneo() async {
    try {
      await _apiService.post(
        '/torneos/admin/$_userId/terminar',
        data: {},
        parser: (data) => data,
      );
      notificationService.showSuccess(context, "Torneo terminado exitosamente");
      _cargarTorneo();
    } catch (e) {
      notificationService.showError(context, "Error al terminar el torneo");
    }
  }

  Future<void> _borrarTorneo() async {
    try {
      _apiService.setContext(context);
      await _apiService.post(
        '/torneos/admin/$_userId/borrar',
        parser: (data) => data,
        showMessages: true,
      );
      notificationService.showSuccess(context, "Torneo eliminado exitosamente");
      HomePage.actualizarEstadisticas(context);
      Navigator.pop(context);
    } catch (_) {}
  }

  Future<void> _actualizarFechaFin() async {
    if (_torneo == null) return;

    final fecha = await showDatePicker(
      context: context,
      initialDate: _torneo!.fechaFin,
      firstDate: _torneo!.fechaInicio,
      lastDate: _torneo!.fechaInicio.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(AppColors.primaryGreen),
              onPrimary: Colors.white,
              surface: Color(AppColors.darkGreen),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_torneo!.fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(AppColors.primaryGreen),
              onPrimary: Colors.white,
              surface: Color(AppColors.darkGreen),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora == null) return;

    final nuevaFecha = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    try {
      await _apiService.put(
        '/torneos/$_userId/fecha_fin',
        data: {
          'fecha_fin': nuevaFecha.toUtc().toIso8601String(),
        },
        parser: (data) => data,
      );
      notificationService.showSuccess(
          context, "Fecha de fin actualizada exitosamente");
      _cargarTorneo();
    } catch (e) {
      notificationService.showError(
          context, "Error al actualizar la fecha de fin");
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_torneo == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(AppColors.darkGreen),
          title: const Text('Administrar Torneo'),
        ),
        body: const Center(
          child: Text('No se pudo cargar el torneo'),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(AppColors.darkGreen),
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Administrar Torneo',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'YesevaOne',
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(AppColors.darkGreen).withOpacity(0.7),
                        Color(AppColors.darkGreen).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
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
                          'Código del torneo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'YesevaOne',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _torneo!.codeId.split('-').map((direccion) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  direccion == 'up'
                                      ? Icons.north
                                      : direccion == 'down'
                                          ? Icons.south
                                          : direccion == 'left'
                                              ? Icons.west
                                              : Icons.east,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
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
                          'Información general',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'YesevaOne',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _torneo!.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'YesevaOne',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Color(AppColors.primaryGreen).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _torneo!.modalidad,
                            style: TextStyle(
                              color: Color(AppColors.primaryGreen),
                              fontSize: 14,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
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
                          'Fechas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'YesevaOne',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Inicio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'YesevaOne',
                                    ),
                                  ),
                                  Text(
                                    '${_torneo!.fechaInicio.day}/${_torneo!.fechaInicio.month}/${_torneo!.fechaInicio.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${_torneo!.fechaInicio.hour}:${_torneo!.fechaInicio.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'YesevaOne',
                                    ),
                                  ),
                                  Text(
                                    '${_torneo!.fechaFin.day}/${_torneo!.fechaFin.month}/${_torneo!.fechaFin.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${_torneo!.fechaFin.hour}:${_torneo!.fechaFin.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_torneo!.finalizado)
                              TextButton(
                                onPressed: _actualizarFechaFin,
                                child: Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    color: Color(AppColors.primaryGreen),
                                    fontFamily: 'YesevaOne',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
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
                          'Estado',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'YesevaOne',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _torneo!.finalizado
                                    ? Colors.red.withOpacity(0.2)
                                    : Color(AppColors.primaryGreen)
                                        .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _torneo!.finalizado ? 'Finalizado' : 'En curso',
                                style: TextStyle(
                                  color: _torneo!.finalizado
                                      ? Colors.red
                                      : Color(AppColors.primaryGreen),
                                  fontSize: 14,
                                  fontFamily: 'YesevaOne',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_torneo!.finalizado &&
                            (_torneo!.ganadorVersus != null ||
                                _torneo!.ganadorIndividual != null)) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Ganador:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _torneo!.modalidad == 'Versus'
                                ? (_torneo!.ganadorVersus == true
                                    ? 'Equipo A'
                                    : 'Equipo B')
                                : _torneo!.ganadorIndividual!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_torneo!.ubicacionAproximada) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
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
                            'Configuración',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Ubicación aproximada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(AppColors.primaryGreen)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_torneo!.metrosAprox} metros',
                                  style: TextStyle(
                                    color: Color(AppColors.primaryGreen),
                                    fontSize: 14,
                                    fontFamily: 'YesevaOne',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_torneo!.modalidad == 'Versus' &&
                    _torneo!.ubicacionAproximada) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
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
                            'Ubicación A',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _torneo!.nombreUbicacionA,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _torneo!.ubicacionALatitud,
                                    _torneo!.ubicacionALongitud,
                                  ),
                                  initialZoom: 15,
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
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          _torneo!.ubicacionALatitud,
                                          _torneo!.ubicacionALongitud,
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
                                            color:
                                                Color(AppColors.primaryGreen),
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
                        ],
                      ),
                    ),
                  ),
                  if (_torneo!.ubicacionBLatitud != null &&
                      _torneo!.ubicacionBLongitud != null &&
                      _torneo!.nombreUbicacionB != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
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
                              'Ubicación B',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'YesevaOne',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _torneo!.nombreUbicacionB!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'YesevaOne',
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      _torneo!.ubicacionBLatitud!,
                                      _torneo!.ubicacionBLongitud!,
                                    ),
                                    initialZoom: 15,
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
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            _torneo!.ubicacionBLatitud!,
                                            _torneo!.ubicacionBLongitud!,
                                          ),
                                          width: 40,
                                          height: 40,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Color(AppColors.primaryGreen)
                                                      .withOpacity(0.3),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                            ),
                                            child: Icon(
                                              Icons.location_on,
                                              color:
                                                  Color(AppColors.primaryGreen),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else if (_torneo!.modalidad == 'Individual' &&
                    _torneo!.ubicacionAproximada) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
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
                            'Ubicación',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _torneo!.nombreUbicacionA,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _torneo!.ubicacionALatitud,
                                    _torneo!.ubicacionALongitud,
                                  ),
                                  initialZoom: 15,
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
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          _torneo!.ubicacionALatitud,
                                          _torneo!.ubicacionALongitud,
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
                                            color:
                                                Color(AppColors.primaryGreen),
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
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (!_torneo!.finalizado)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _terminarTorneo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppColors.primaryGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Terminar Torneo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'YesevaOne',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Color(AppColors.darkGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  '¿Eliminar torneo?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'YesevaOne',
                                  ),
                                ),
                                content: const Text(
                                  'Esta acción no se puede deshacer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'YesevaOne',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Color(AppColors.primaryGreen),
                                        fontFamily: 'YesevaOne',
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _borrarTorneo();
                                    },
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'YesevaOne',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Eliminar Torneo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'YesevaOne',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DireccionGesto {
  arriba,
  abajo,
  izquierda,
  derecha,
}
