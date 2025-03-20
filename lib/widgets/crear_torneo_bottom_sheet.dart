import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../models/torneo.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../screens/seleccionar_ubicacion_page.dart';

class CrearTorneoBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const CrearTorneoBottomSheet({super.key, required this.scrollController});

  @override
  State<CrearTorneoBottomSheet> createState() => _CrearTorneoBottomSheetState();
}

class _CrearTorneoBottomSheetState extends State<CrearTorneoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nombreUbicacionAController = TextEditingController();
  final _nombreUbicacionBController = TextEditingController();
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();

  String _modalidad = 'Individual';
  bool _ubicacionAproximada = false;
  DateTime _fechaInicio = DateTime.now();
  TimeOfDay _horaInicio = TimeOfDay.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaFin = TimeOfDay.now();
  int _metrosTolerancia = 100;

  LatLng? _ubicacionA;
  LatLng? _ubicacionB;

  static const List<int> _metrosOptions = [
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
    2100,
    2200,
    2300,
    2400,
    2500,
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreUbicacionAController.dispose();
    _nombreUbicacionBController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: esInicio ? DateTime.now() : _fechaInicio,
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 1));
          }
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
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

    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaFin = hora;
        }
      });
    }
  }

  Future<void> _seleccionarUbicacion(bool esEquipoA) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarUbicacionPage(
          titulo:
              'Seleccionar ubicación ${esEquipoA ? "Equipo A" : "Equipo B"}',
          ubicacionInicial: esEquipoA ? _ubicacionA : _ubicacionB,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (esEquipoA) {
          _ubicacionA = result['location'] as LatLng;
        } else {
          _ubicacionB = result['location'] as LatLng;
        }
      });
    }
  }

  Future<void> _crearTorneo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ubicacionAproximada) {
      if (_modalidad == 'Versus') {
        if (_ubicacionA == null || _ubicacionB == null) {
          notificationService.showError(
              context, "Por favor selecciona la ubicación para ambos equipos");
          return;
        }
      } else if (_ubicacionA == null) {
        notificationService.showError(
            context, "Por favor selecciona la ubicación");
        return;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        notificationService.showError(context, "Error de autenticación");
        return;
      }

      DateTime fechaInicioCompleta = DateTime(
        _fechaInicio.year,
        _fechaInicio.month,
        _fechaInicio.day,
        _horaInicio.hour,
        _horaInicio.minute,
      );

      DateTime fechaFinCompleta = DateTime(
        _fechaFin.year,
        _fechaFin.month,
        _fechaFin.day,
        _horaFin.hour,
        _horaFin.minute,
      );

      // Crear directamente un objeto Torneo
      final Torneo nuevoTorneo = Torneo(
          id: '', // Se generará en el backend
          idCreator: userId,
          nombre: _nombreController.text,
          modalidad: _modalidad,
          ubicacionALatitud: _ubicacionA?.latitude ?? 0.0,
          ubicacionALongitud: _ubicacionA?.longitude ?? 0.0,
          nombreUbicacionA: _nombreUbicacionAController.text,
          ubicacionBLatitud:
              _modalidad == 'Versus' ? _ubicacionB?.latitude : null,
          ubicacionBLongitud:
              _modalidad == 'Versus' ? _ubicacionB?.longitude : null,
          nombreUbicacionB:
              _modalidad == 'Versus' ? _nombreUbicacionBController.text : null,
          fechaInicio: fechaInicioCompleta,
          fechaFin: fechaFinCompleta,
          ubicacionAproximada: _ubicacionAproximada,
          metrosAprox: _ubicacionAproximada ? _metrosTolerancia : null,
          finalizado: false,
          codeId: '', // Se generará en el backend
          ganadorVersus: null,
          ganadorIndividual: null);

      // Utilizar el método toJson del modelo Torneo
      final Map<String, dynamic> torneoData = nuevoTorneo.toJson();

      // Eliminar campos que no se deben enviar al backend al crear
      torneoData.remove('id');
      torneoData.remove('code_id');
      torneoData.remove('finalizado');
      torneoData.remove('ganador_versus');
      torneoData.remove('ganador_individual');

      _apiService.setContext(context);
      await _apiService.post('/torneos',
          data: torneoData,
          parser: (data) => Torneo.fromJson(data),
          showMessages: true);

      if (!mounted) return;
      notificationService.showSuccess(context, "Torneo creado exitosamente");
      Navigator.pop(context);
    } catch (_) {
      // El error ya se muestra en el servicio de API
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Crear Torneo',
                    style: TextStyle(
                      fontFamily: 'YesevaOne',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del torneo',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(AppColors.primaryGreen)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _modalidad,
                      isExpanded: true,
                      dropdownColor: Color(AppColors.darkGreen),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: 'Individual',
                          child: Text('Individual'),
                        ),
                        DropdownMenuItem(
                          value: 'Versus',
                          child: Text('Versus'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _modalidad = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Inicio: ${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hora: ${_horaInicio.format(context)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _seleccionarFecha(false),
                        child: Text(
                          'Fin: ${_fechaFin.day}/${_fechaFin.month}/${_fechaFin.year}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _seleccionarHora(false),
                        child: Text(
                          'Hora: ${_horaFin.format(context)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Ubicación aproximada',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _ubicacionAproximada,
                  onChanged: (bool value) {
                    setState(() {
                      _ubicacionAproximada = value;
                    });
                  },
                  activeColor: Color(AppColors.primaryGreen),
                ),
                if (_ubicacionAproximada) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _metrosTolerancia,
                        isExpanded: true,
                        dropdownColor: Color(AppColors.darkGreen),
                        style: const TextStyle(color: Colors.white),
                        items: _metrosOptions.map((int metros) {
                          return DropdownMenuItem<int>(
                            value: metros,
                            child: Text('$metros metros'),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              _metrosTolerancia = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_modalidad == 'Versus') ...[
                    TextFormField(
                      controller: _nombreUbicacionAController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la ubicación A',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(AppColors.primaryGreen)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_ubicacionAproximada &&
                            _ubicacionA != null &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor ingresa el nombre de la ubicación A';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _seleccionarUbicacion(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.darkGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(AppColors.primaryGreen),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nombreUbicacionAController.text == ''
                                    ? 'Seleccionar ubicación A'
                                    : _nombreUbicacionAController.text,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_ubicacionA != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _ubicacionA!,
                              initialZoom: 15,
                              interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none),
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
                                  Marker(
                                    point: _ubicacionA!,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreUbicacionBController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la ubicación B',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(AppColors.primaryGreen)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_ubicacionAproximada &&
                            _ubicacionB != null &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor ingresa el nombre de la ubicación B';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _seleccionarUbicacion(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.darkGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(AppColors.primaryGreen),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nombreUbicacionBController.text == ''
                                    ? 'Seleccionar ubicación B'
                                    : _nombreUbicacionBController.text,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_ubicacionB != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _ubicacionB!,
                              initialZoom: 15,
                              interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none),
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
                                  Marker(
                                    point: _ubicacionB!,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    TextFormField(
                      controller: _nombreUbicacionAController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la ubicación',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(AppColors.primaryGreen)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_ubicacionAproximada &&
                            _ubicacionA != null &&
                            (value == null || value.isEmpty)) {
                          return 'Por favor ingresa el nombre de la ubicación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _seleccionarUbicacion(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.darkGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(AppColors.primaryGreen),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nombreUbicacionAController.text == ''
                                    ? 'Seleccionar ubicación'
                                    : _nombreUbicacionAController.text,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_ubicacionA != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _ubicacionA!,
                              initialZoom: 15,
                              interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none),
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
                                  Marker(
                                    point: _ubicacionA!,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
                if (_modalidad == 'Versus' && !_ubicacionAproximada) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreUbicacionAController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la ubicación A',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(AppColors.primaryGreen)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_modalidad == 'Versus' &&
                          (value == null || value.isEmpty)) {
                        return 'Por favor ingresa el nombre de la ubicación A';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreUbicacionBController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la ubicación B',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(AppColors.primaryGreen)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_modalidad == 'Versus' &&
                          (value == null || value.isEmpty)) {
                        return 'Por favor ingresa el nombre de la ubicación B';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _crearTorneo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Crear Torneo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ));
  }
}
