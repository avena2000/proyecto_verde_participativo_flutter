import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class SeleccionarUbicacionPage extends StatefulWidget {
  final String titulo;
  final LatLng? ubicacionInicial;

  const SeleccionarUbicacionPage({
    super.key,
    required this.titulo,
    this.ubicacionInicial,
  });

  @override
  State<SeleccionarUbicacionPage> createState() =>
      _SeleccionarUbicacionPageState();
}

class _SeleccionarUbicacionPageState extends State<SeleccionarUbicacionPage>
    with TickerProviderStateMixin {
  final notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  late final _mapController = AnimatedMapController(vsync: this);
  Timer? _debounce;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String? _selectedLocationName;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.ubicacionInicial != null) {
      _selectedLocation = widget.ubicacionInicial;
      _selectedLocationName = 'Ubicación seleccionada';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.centerOnPoint(widget.ubicacionInicial!, zoom: 15);
      });
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _searchLocation();
    });
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
          if (_selectedLocation == null) {
            _selectedLocation = _currentLocation;
            _mapController.centerOnPoint(_currentLocation!, zoom: 15);
          }
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      // Ubicación por defecto: Ciudad de México
      setState(() {
        _currentLocation = const LatLng(19.4326, -99.1332);
        if (_selectedLocation == null) {
          _selectedLocation = _currentLocation;
          _mapController.centerOnPoint(_currentLocation!, zoom: 15);
        }
      });
    }

    // Una vez que tenemos la ubicación, configuramos el listener
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _locationService.searchLocation(
        query,
        nearLocation: _currentLocation ?? _selectedLocation,
      );

      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        notificationService.showError(context, "Error al buscar ubicación");
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    setState(() {
      _selectedLocation = result['location'] as LatLng;
      _selectedLocationName = result['name'] as String;
      _searchResults = [];
    });
    _mapController.centerOnPoint(_selectedLocation!, zoom: 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Color(AppColors.darkGreen),
        elevation: 0,
        title: Text(
          widget.titulo,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'YesevaOne',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController.mapController,
            options: MapOptions(
              initialCenter: widget.ubicacionInicial ??
                  _currentLocation ??
                  const LatLng(19.4326, -99.1332),
              initialZoom: 15,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _selectedLocationName = 'Ubicación seleccionada';
                  _searchResults = [];
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
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
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(AppColors.primaryGreen).withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ubicación...',
                      border: InputBorder.none,
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result['name'] as String),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentLocation != null)
            FloatingActionButton(
              heroTag: 'location',
              backgroundColor: Color(AppColors.darkGreen),
              onPressed: () {
                _mapController.centerOnPoint(_currentLocation!, zoom: 15);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'confirm',
            backgroundColor: Color(AppColors.primaryGreen),
            onPressed: _selectedLocation == null
                ? null
                : () {
                    Navigator.pop(context, {
                      'location': _selectedLocation,
                      'name': _selectedLocationName,
                    });
                  },
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
