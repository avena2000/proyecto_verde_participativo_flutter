import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:proyecto_verde_participativo/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _setFullScreenMode();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiService().setContext(context);
    });
    _cargarEmail();
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

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _cargarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('username') ?? '';
    });
  }

  Future<void> _guardarInformacionPersonal() async {
    if (!_formKey.currentState!.validate()) return;

    // Proporcionar retroalimentación háptica
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final nombreFormateado = _nombreController.text.trim();
      final apellidoFormateado = _apellidoController.text.trim();

      final _ = await _apiService.put(
        '/users/$userId/basic-info',
        data: {
          'nombre': nombreFormateado,
          'apellido': apellidoFormateado,
          'numero': _telefonoController.text,
        },
        showMessages: true,
      );

      await prefs.setBool('isPersonalInformation', true);
      await prefs.setString('nombre', nombreFormateado);
      await prefs.setString('apellido', apellidoFormateado);
      await prefs.setString('telefono', _telefonoController.text);

      if (!mounted) return;

      notificationService.showSuccess(
          context, "Información guardada exitosamente");

      Navigator.pushAndRemoveUntil(
        context,
        CustomPageTransition(page: HomePage(key: HomePage.homeKey)),
        (route) => false,
      );
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
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
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Color(AppColors.darkGreen),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(AppColors.primaryGreen)
                                  .withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color:
                                Color(AppColors.primaryGreen).withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '¡Completa tu perfil!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'YesevaOne',
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Para brindarte una mejor experiencia',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _emailController,
                              enabled: false,
                              label: 'Correo electrónico',
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nombreController,
                              label: 'Nombre',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su nombre';
                                }
                                final RegExp caracteresPermitidos =
                                    RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$');
                                if (!caracteresPermitidos.hasMatch(value)) {
                                  return 'El nombre no debe contener caracteres especiales';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  String tempValue = value;
                                  final List<String> words =
                                      tempValue.split(' ');
                                  final List<String> capitalizedWords = [];

                                  for (final word in words) {
                                    if (word.isNotEmpty) {
                                      capitalizedWords.add(
                                          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
                                    } else {
                                      capitalizedWords.add('');
                                    }
                                  }

                                  final String formattedValue =
                                      capitalizedWords.join(' ');

                                  if (tempValue != formattedValue) {
                                    final currentPosition =
                                        _nombreController.selection.start;

                                    _nombreController.value = TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                          offset: currentPosition <
                                                  formattedValue.length
                                              ? currentPosition
                                              : formattedValue.length),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _apellidoController,
                              label: 'Apellido',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su apellido';
                                }
                                final RegExp caracteresPermitidos =
                                    RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]+$');
                                if (!caracteresPermitidos.hasMatch(value)) {
                                  return 'El apellido no debe contener caracteres especiales';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  String tempValue = value;
                                  final List<String> words =
                                      tempValue.split(' ');
                                  final List<String> capitalizedWords = [];

                                  for (final word in words) {
                                    if (word.isNotEmpty) {
                                      capitalizedWords.add(
                                          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
                                    } else {
                                      capitalizedWords.add('');
                                    }
                                  }

                                  final String formattedValue =
                                      capitalizedWords.join(' ');

                                  if (tempValue != formattedValue) {
                                    final currentPosition =
                                        _apellidoController.selection.start;

                                    _apellidoController.value =
                                        TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                          offset: currentPosition <
                                                  formattedValue.length
                                              ? currentPosition
                                              : formattedValue.length),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su teléfono';
                                }
                                final RegExp soloDigitos =
                                    RegExp(r'^[0-9]{10}$');
                                if (!soloDigitos.hasMatch(value)) {
                                  return 'El teléfono no existe';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final RegExp soloDigitos = RegExp(r'[0-9]');
                                  String digitsOnly = value
                                      .split('')
                                      .where((c) => soloDigitos.hasMatch(c))
                                      .join('');

                                  if (digitsOnly.length > 10) {
                                    digitsOnly = digitsOnly.substring(0, 10);
                                  }

                                  if (value != digitsOnly) {
                                    final currentPosition =
                                        _telefonoController.selection.start;
                                    final newPosition = currentPosition -
                                        (value.length - digitsOnly.length);

                                    _telefonoController.value =
                                        TextEditingValue(
                                      text: digitsOnly,
                                      selection: TextSelection.collapsed(
                                          offset: newPosition > 0
                                              ? newPosition
                                              : 0),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 40),
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(AppColors.primaryGreen),
                                    Color(AppColors.primaryGreenDark),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(AppColors.primaryGreen)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _isLoading
                                      ? null
                                      : _guardarInformacionPersonal,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Guardar Información',
                                            style: TextStyle(
                                              fontFamily: 'YesevaOne',
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Color(AppColors.primaryGreen),
              size: 24,
            ),
          ),
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
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: enabled
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}
