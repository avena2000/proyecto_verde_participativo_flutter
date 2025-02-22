import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_verde_participativo/screens/welcome_page.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/screens/personal_info_page.dart';
import 'package:proyecto_verde_participativo/models/user_access.dart';
import 'package:proyecto_verde_participativo/models/user_basic_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/acciones_provider.dart';
import 'providers/personaje_provider.dart';
import 'services/api_service.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/config/.env");

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

  final apiService = ApiService();
  final initialRoute = await checkInitialRoute();

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

class MyApp extends StatelessWidget {
  final Widget initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto Verde Participativo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: initialRoute,
    );
  }
}
