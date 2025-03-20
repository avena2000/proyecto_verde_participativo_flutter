import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

// Importaciones internas
import 'package:proyecto_verde_participativo/libraries/pwa_install.dart';
import 'package:proyecto_verde_participativo/screens/welcome_page.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/screens/personal_info_page.dart';
import 'package:proyecto_verde_participativo/models/user_access.dart';
import 'package:proyecto_verde_participativo/models/user_basic_info.dart';
import 'providers/acciones_provider.dart';
import 'providers/personaje_provider.dart';
import 'services/api_service.dart';

// Constantes de la aplicación
class AppConstants {
  // Colores
  static const Color primaryColor = Color(0xFF34A853);
  static const Color darkGreen1 = Color(0xFF1E4C3C);
  static const Color darkGreen2 = Color(0xFF1A3B2E);
  static const Color warningColor = Colors.amber;

  // Estilos
  static const TextStyle titleStyle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'YesevaOne',
    shadows: [
      Shadow(
        color: primaryColor,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );

  // Decoraciones
  static BoxDecoration instructionContainerDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration warningContainerDecoration = BoxDecoration(
    color: warningColor.withOpacity(0.2),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: warningColor.withOpacity(0.5),
      width: 1,
    ),
  );
}

Future<Widget> checkInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  final apiService = ApiService();

  if (userId == null) return const WelcomePage();

  try {
    final dataAnswer = await apiService.get(
      '/auth/relogin/$userId',
      parser: (data) => UserAccess.fromJson(data),
    );

    // Obtener información adicional del usuario
    if (dataAnswer.isPersonalInformation) {
      final userInfo = await apiService.get(
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

    if (dataAnswer.isPersonalInformation) {
      return HomePage(key: HomePage.homeKey);
    } else {
      return const PersonalInfoPage();
    }
  } catch (_) {
    return const WelcomePage();
  }
}

/// Detecta si el dispositivo es Android basado en el user agent
bool isAndroid() {
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('android') ||
      (userAgent.contains('mobile') && !userAgent.contains('iphone'));
}

/// Detecta si el dispositivo es iOS basado en el user agent
bool isIOS() {
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') || userAgent.contains('ipad');
}

/// Inicializa y ejecuta la aplicación principal con los providers necesarios
void _runMainApp(ApiService apiService, Widget initialRoute) {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccionesProvider(apiService)),
        ChangeNotifierProvider(create: (_) => PersonajeProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

/// Configura la interfaz de usuario del sistema para dispositivos nativos
void _configureNativeUI() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/config/.env");
  final apiService = ApiService();

  if (kIsWeb) {
    // Configurar PWAInstall y establecer callback de instalación
    PWAInstall().setup(installCallback: () {
      debugPrint('APP INSTALLED!');
    });

    // Esperar un breve momento para que se detecte el modo de lanzamiento
    await Future.delayed(const Duration(milliseconds: 500));

    final pwaInstall = PWAInstall();
    final launchMode = pwaInstall.launchMode;

    debugPrint(
        'kIsWeb - Modo de lanzamiento: ${launchMode?.shortLabel ?? "no detectado"}');

    // Si la aplicación ya está instalada, ejecutar normalmente
    if (launchMode?.installed == true || kDebugMode) {
      debugPrint(
          'Omitiendo pantalla de instalación, continuando con la aplicación normal');
      final initialRoute = await checkInitialRoute();
      _runMainApp(apiService, initialRoute);
      return;
    }

    // Si no está instalada, mostrar pantalla de instalación según el dispositivo
    if (isAndroid()) {
      debugPrint('Dispositivo detectado: Android');
      runApp(const InstallPWAScreen(isIOS: false));
    } else if (isIOS()) {
      debugPrint('Dispositivo detectado: iOS');
      runApp(const InstallPWAScreen(isIOS: true));
    } else {
      debugPrint('Dispositivo detectado: No móvil');
      runApp(const NonMobileDeviceWarning());
    }
  } else {
    // Configuración para aplicación nativa
    _configureNativeUI();
    final initialRoute = await checkInitialRoute();
    _runMainApp(apiService, initialRoute);
  }
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViVe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: initialRoute,
    );
  }
}

class InstallPWAScreen extends StatelessWidget {
  final bool isIOS;

  const InstallPWAScreen({super.key, required this.isIOS});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppConstants.darkGreen1,
                AppConstants.darkGreen2,
              ],
            ),
          ),
          child: SafeArea(
            bottom: true,
            top: true,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 40.0),
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo y título con efecto de sombra
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              size: 80,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Título con efecto de sombra
                          const Text('ViVe', style: AppConstants.titleStyle),
                          const SizedBox(height: 16),
                          // Descripción principal
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Para una mejor experiencia, es necesario instalar la aplicación en tu dispositivo',
                                  style: AppConstants.bodyTextStyle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'La instalación es rápida, segura y te permitirá acceder a todas las funciones incluso sin conexión a internet.',
                                  style: AppConstants.smallTextStyle.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Contenedor de instrucciones
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration:
                                AppConstants.instructionContainerDecoration,
                            child: isIOS
                                ? _buildIOSInstructions()
                                : _buildAndroidInstructions(),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                // Botones de instalación en un contenedor fijo en la parte inferior
                _buildInstallButtonContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallButtonContainer() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppConstants.darkGreen2,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isIOS && PWAInstall().installPromptEnabled)
            _buildInstallButton(),
          if (!isIOS && !PWAInstall().installPromptEnabled)
            Column(
              children: [
                _buildWarningMessage(
                  'Su dispositivo no es compatible con la instalación directa o la aplicación ya se encuentra instalada. Por favor, use Chrome para instalar esta aplicación.',
                ),
                const SizedBox(height: 16),
              ],
            ),
          if (isIOS)
            ElevatedButton.icon(
              onPressed: () async {},
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('¡Instálala ya!'),
              style: _installButtonStyle(),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallButton() {
    return ElevatedButton.icon(
      onPressed: () {
        try {
          // Configurar el callback de instalación antes de mostrar el prompt
          PWAInstall().onAppInstalled = () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('pwaInstalled', true);

            // Recargar la página para que se detecte como instalada
            web.window.location.reload();
          };

          // Mostrar el prompt de instalación
          PWAInstall().promptInstall_();
        } catch (e) {
          debugPrint(e.toString());
        }
      },
      icon: const Icon(Icons.download),
      label: const Text('Instalar ahora'),
      style: _installButtonStyle(),
    );
  }

  ButtonStyle _installButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      minimumSize: const Size(double.infinity, 56),
    );
  }

  Widget _buildWarningMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppConstants.warningContainerDecoration,
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppConstants.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppConstants.bodyTextStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instrucciones para iOS:',
          style: AppConstants.sectionTitleStyle,
        ),
        const SizedBox(height: 16),
        _buildInstructionStep(
          1,
          'Toca el botón "Compartir" en la barra de Safari',
          Icons.ios_share,
        ),
        _buildInstructionStep(
          2,
          'Desplázate y selecciona "Añadir a pantalla de inicio"',
          Icons.add_to_home_screen,
        ),
        _buildInstructionStep(
          3,
          'Confirma tocando "Añadir" en la esquina superior derecha',
          Icons.check_circle_outline,
        ),
        _buildInstructionStep(
          4,
          'Una vez instalada, cierra Safari y abre la app desde tu pantalla de inicio',
          Icons.home,
        ),
        const SizedBox(height: 16),
        _buildInfoMessage(
          'La aplicación aparecerá en tu pantalla de inicio como cualquier otra app',
        ),
      ],
    );
  }

  Widget _buildAndroidInstructions() {
    // Si el botón de instalación no está disponible, mostrar instrucciones alternativas
    if (!PWAInstall().installPromptEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instrucciones para Android:',
            style: AppConstants.sectionTitleStyle,
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            1,
            'Abre esta página en Google Chrome',
            Icons.open_in_browser,
          ),
          _buildInstructionStep(
            2,
            'Toca el menú (tres puntos) en la esquina superior derecha',
            Icons.more_vert,
          ),
          _buildInstructionStep(
            3,
            'Selecciona "Instalar aplicación" o "Añadir a pantalla de inicio"',
            Icons.add_to_home_screen,
          ),
          _buildInstructionStep(
            4,
            'Confirma la instalación en el diálogo que aparece',
            Icons.check_circle_outline,
          ),
          _buildInstructionStep(
            5,
            'Una vez instalada, abre la app desde tu pantalla de inicio',
            Icons.home,
          ),
          const SizedBox(height: 16),
          _buildInfoMessage(
            'Si ya has instalado la aplicación, búscala en tu dispositivo.',
          ),
        ],
      );
    }

    // Instrucciones normales cuando el botón de instalación está disponible
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instrucciones para Android:',
          style: AppConstants.sectionTitleStyle,
        ),
        const SizedBox(height: 16),
        _buildInstructionStep(
          1,
          'Toca el botón "Instalar ahora" a continuación',
          Icons.download,
        ),
        _buildInstructionStep(
          2,
          'Confirma la instalación en el diálogo que aparece',
          Icons.check_circle_outline,
        ),
        _buildInstructionStep(
          3,
          'Espera a que se complete la instalación',
          Icons.hourglass_bottom,
        ),
        _buildInstructionStep(
          4,
          'La aplicación se abrirá automáticamente después de instalarse',
          Icons.open_in_new,
        ),
        const SizedBox(height: 16),
        _buildInfoMessage(
          'La aplicación funcionará sin conexión y tendrás una mejor experiencia',
        ),
      ],
    );
  }

  Widget _buildInfoMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppConstants.warningContainerDecoration,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppConstants.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppConstants.smallTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppConstants.bodyTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class NonMobileDeviceWarning extends StatelessWidget {
  const NonMobileDeviceWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mobile_off,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Esta aplicación solo está disponible para dispositivos móviles',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Por favor, accede desde tu teléfono móvil para usar la aplicación.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
