import 'package:flutter/material.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class ConfiguracionBottomSheet extends StatefulWidget {
  final Function() onLogout;
  final Function() onUpdateComplete;

  const ConfiguracionBottomSheet({
    super.key,
    required this.onLogout,
    required this.onUpdateComplete,
  });

  @override
  State<ConfiguracionBottomSheet> createState() =>
      _ConfiguracionBottomSheetState();
}

class _ConfiguracionBottomSheetState extends State<ConfiguracionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  String? _selectedSlogan;
  List<String> _availableSlogans = ["ViVe tu mejor vida"];
  final notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarSlogans();
  }

  Future<void> _cargarSlogans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await _apiService.get('/users/$userId/medallas/slogans');
      if (response != null) {
        setState(() {
          _availableSlogans = [
            "ViVe tu mejor vida",
            ...List<String>.from(response)
          ];
        });
      }
    } catch (e) {
      notificationService.showError(
        context,
        'Error al cargar los slogans disponibles',
      );
    }
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreController.text = prefs.getString('nombre') ?? '';
      _apellidoController.text = prefs.getString('apellido') ?? '';
      _selectedSlogan = prefs.getString('slogan') ?? _availableSlogans[0];
    });
  }

  Future<void> _actualizarDatos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) return;

      await _apiService.put('/users/$userId/profile/edit', data: {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'slogan': _selectedSlogan,
      });

      await prefs.setString('nombre', _nombreController.text);
      await prefs.setString('apellido', _apellidoController.text);
      await prefs.setString('slogan', _selectedSlogan ?? _availableSlogans[0]);

      widget.onUpdateComplete();
    } catch (e) {
      notificationService.showError(
        context,
        'Error al actualizar los datos',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 6),
        child: Form(
          key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Configuración',
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
                labelText: 'Nombre',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(AppColors.primaryGreen)),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                return null;
              },
              onChanged: (_) => _actualizarDatos(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Apellido',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(AppColors.primaryGreen)),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu apellido';
                }
                return null;
              },
              onChanged: (_) => _actualizarDatos(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSlogan ?? _availableSlogans[0],
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.black87,
              decoration: InputDecoration(
                labelText: 'Frase personal',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(AppColors.primaryGreen)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _availableSlogans.map((String slogan) {
                return DropdownMenuItem<String>(
                  value: slogan,
                  child: Text(
                    slogan,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSlogan = newValue;
                });
                _actualizarDatos();
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cerrarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }
}
