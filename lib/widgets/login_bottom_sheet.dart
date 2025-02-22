import 'package:flutter/material.dart';
import 'package:proyecto_verde_participativo/models/user_access.dart';
import 'package:proyecto_verde_participativo/models/user_basic_info.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/screens/personal_info_page.dart';
import 'package:proyecto_verde_participativo/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/functions.dart';
import 'registro_bottom_sheet.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LoginBottomSheet(),
    );
  }

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutExpo,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dataAnswer = await _apiService.post(
        '/auth/login',
        data: {
          'username': _usernameController.text,
          'password': hashPassword(_passwordController.text),
        },
        parser: (data) => UserAccess.fromJson(data),
      );

      if (!mounted) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Obtener información adicional del usuario
      if (dataAnswer.isPersonalInformation) {
        final userInfo = await _apiService.get(
          '/users/${dataAnswer.id}/basic-info',
          parser: (data) => UserBasicInfo.fromJson(data),
        );
        // Guardar información personal si existe
        await prefs.setString('nombre', userInfo.nombre);
        await prefs.setString('apellido', userInfo.apellido);
        await prefs.setString('telefono', userInfo.telefono);
        await prefs.setString('friendId', userInfo.friendId);
      }
      // Guardar información básica de autenticación
      await prefs.setString('userId', dataAnswer.id);
      await prefs.setString('username', dataAnswer.username);
      await prefs.setBool(
          'isPersonalInformation', dataAnswer.isPersonalInformation);

      if (!mounted) return;

      notificationService.showSuccess(context, "Inicio de sesión exitoso");

      Navigator.pop(context);
      if (dataAnswer.isPersonalInformation) {
        Navigator.pushAndRemoveUntil(
          context,
          CustomPageTransition(page: HomePage(key: HomePage.homeKey)),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          CustomPageTransition(page: const PersonalInfoPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      notificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 40,
                      child: Divider(thickness: 3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryGreen),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          RegistroBottomSheet.show(context);
                        },
                        child: Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Color(AppColors.primaryGreen),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
