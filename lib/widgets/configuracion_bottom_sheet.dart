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
  String _selectedSlogan = "ViVe tu mejor vida";
  List<String> _availableSlogans = ["ViVe tu mejor vida"];
  final notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    try {
      // Primero cargamos los slogans disponibles
      await _cargarSlogans();
      // Después cargamos los datos del usuario
      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        notificationService.showError(
          context,
          'Error al cargar los datos',
        );
      }
    }
  }

  Future<void> _cargarSlogans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await _apiService.get('/users/$userId/medallas/slogans');
      if (response != null && mounted) {
        setState(() {
          _availableSlogans = [
            "ViVe tu mejor vida",
            ...List<String>.from(response)
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        notificationService.showError(
          context,
          'Error al cargar los slogans disponibles',
        );
      }
    }
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final savedSlogan = prefs.getString('slogan');
      setState(() {
        _nombreController.text = prefs.getString('nombre') ?? '';
        _apellidoController.text = prefs.getString('apellido') ?? '';
        if (savedSlogan != null && _availableSlogans.contains(savedSlogan)) {
          _selectedSlogan = savedSlogan;
        }
      });
    }
  }

  Future<void> _actualizarDatos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) return;
      final slogan =
          _selectedSlogan == "" ? _availableSlogans[0] : _selectedSlogan;

      // Limpia los espacios al final antes de enviar al API
      final nombreFormateado = _nombreController.text.trim();
      final apellidoFormateado = _apellidoController.text.trim();

      await _apiService.put('/users/$userId/profile/edit', data: {
        'nombre': nombreFormateado,
        'apellido': apellidoFormateado,
        'slogan': slogan,
      });

      await prefs.setString('nombre', nombreFormateado);
      await prefs.setString('apellido', apellidoFormateado);
      await prefs.setString('slogan', _selectedSlogan);

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
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(AppColors.primaryGreen)),
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
                  // Validar que no contenga caracteres especiales
                  final RegExp caracteresPermitidos =
                      RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$');
                  if (!caracteresPermitidos.hasMatch(value)) {
                    return 'El nombre no debe contener caracteres especiales';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Solo capitaliza las palabras sin aplicar trim mientras escribe
                  if (value.isNotEmpty) {
                    // Solo capitaliza las palabras, sin quitar espacios
                    String tempValue = value;
                    final List<String> words = tempValue.split(' ');
                    final List<String> capitalizedWords = [];

                    for (final word in words) {
                      if (word.isNotEmpty) {
                        capitalizedWords.add(
                            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
                      } else {
                        // Preservar espacios múltiples
                        capitalizedWords.add('');
                      }
                    }

                    final String formattedValue = capitalizedWords.join(' ');

                    if (tempValue != formattedValue) {
                      // Preserva la posición del cursor
                      final currentPosition = _nombreController.selection.start;

                      _nombreController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                            offset: currentPosition < formattedValue.length
                                ? currentPosition
                                : formattedValue.length),
                      );
                    }
                  }

                  // Actualiza los datos cuando cambie el texto
                  _actualizarDatos();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Apellido',
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
                  // Validar que no contenga caracteres especiales
                  final RegExp caracteresPermitidos =
                      RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ ]+$');
                  if (!caracteresPermitidos.hasMatch(value)) {
                    return 'El apellido no debe contener caracteres especiales';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Solo capitaliza las palabras sin aplicar trim mientras escribe
                  if (value.isNotEmpty) {
                    // Solo capitaliza las palabras, sin quitar espacios
                    String tempValue = value;
                    final List<String> words = tempValue.split(' ');
                    final List<String> capitalizedWords = [];

                    for (final word in words) {
                      if (word.isNotEmpty) {
                        capitalizedWords.add(
                            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
                      } else {
                        // Preservar espacios múltiples
                        capitalizedWords.add('');
                      }
                    }

                    final String formattedValue = capitalizedWords.join(' ');

                    if (tempValue != formattedValue) {
                      // Preserva la posición del cursor
                      final currentPosition =
                          _apellidoController.selection.start;

                      _apellidoController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                            offset: currentPosition < formattedValue.length
                                ? currentPosition
                                : formattedValue.length),
                      );
                    }
                  }

                  // Actualiza los datos cuando cambie el texto
                  _actualizarDatos();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSlogan,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.black87,
                decoration: InputDecoration(
                  labelText: 'Frase personal',
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
                  if (newValue != null) {
                    setState(() {
                      _selectedSlogan = newValue;
                    });
                    _actualizarDatos();
                  }
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
