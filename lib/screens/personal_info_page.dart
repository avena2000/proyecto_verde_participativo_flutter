import 'package:flutter/material.dart';
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

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarEmail();
  }

  Future<void> _cargarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('username') ?? '';
    });
  }

  Future<void> _guardarInformacionPersonal() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final _ = await _apiService.put(
        '/users/$userId/basic-info',
        data: {
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'numero': _telefonoController.text,
        },
      );

      await prefs.setBool('isPersonalInformation', true);
      await prefs.setString('nombre', _nombreController.text);
      await prefs.setString('apellido', _apellidoController.text);
      await prefs.setString('telefono', _telefonoController.text);

      if (!mounted) return;

      notificationService.showSuccess(context, "Información guardada exitosamente");

      Navigator.pushAndRemoveUntil(
        context,
        CustomPageTransition(page: const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      notificationService.showError(context, "Error al guardar la información");
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
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.primaryGreen).withOpacity(0.1),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(AppColors.primaryGreenDark).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Color(AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Completa tu perfil!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.primaryGreenDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para brindarte una mejor experiencia',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(AppColors.primaryGreenDark).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(AppColors.primaryGreenDark).withOpacity(0.2),
                      ),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: const TextStyle(

                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: TextStyle(
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        prefixIcon: Icon(
                          Icons.email,
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(AppColors.primaryGreenDark).withOpacity(0.2),
                      ),
                    ),
                    child: TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(AppColors.primaryGreenDark).withOpacity(0.2),
                      ),
                    ),
                    child: TextFormField(
                      controller: _apellidoController,
                      decoration: InputDecoration(
                        labelText: 'Apellido',
                        labelStyle: TextStyle(
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su apellido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(AppColors.primaryGreenDark).withOpacity(0.2),
                      ),
                    ),
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        labelStyle: TextStyle(
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Color(AppColors.primaryGreenDark),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su teléfono';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarInformacionPersonal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.primaryGreen),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Guardar Información',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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