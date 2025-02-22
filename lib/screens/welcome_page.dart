import 'package:flutter/material.dart' hide CarouselController;
import 'package:proyecto_verde_participativo/models/user_access.dart';
import 'package:proyecto_verde_participativo/models/user_basic_info.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/screens/personal_info_page.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widgets/login_bottom_sheet.dart';
import '../widgets/registro_bottom_sheet.dart';
import 'dart:async';
import '../constants/colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController controller = PageController();
  int activeIndex = 0;
  Timer? _timer;
  bool _isUserInteracting = false;
  final ApiService _apiService = ApiService();

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;
    try {
      final dataAnswer = await _apiService.get(
        '/auth/relogin/$userId',
        parser: (data) => UserAccess.fromJson(data),
      );

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
    } catch (_) {}
  }

  final List<SlideInfo> slides = [
    SlideInfo(
      title: "Bienvenido a EcoApp",
      description: "Tu compañero para un estilo de vida más sostenible",
      icon: Icons.eco,
    ),
    SlideInfo(
      title: "Reduce tu Huella",
      description: "Aprende a reducir tu impacto ambiental día a día",
      icon: Icons.nature_people,
    ),
    SlideInfo(
      title: "Únete a la Comunidad",
      description: "Conecta con otros eco-guerreros y comparte experiencias",
      icon: Icons.group,
    ),
    SlideInfo(
      title: "Identifica Plantas",
      description:
          "Toma fotos de plantas y gana recompensas mientras aprendes sobre la naturaleza",
      icon: Icons.camera_alt,
    ),
    SlideInfo(
      title: "Alerta de Plagas",
      description:
          "Mantén informada a tu comunidad sobre plagas y enfermedades en plantas",
      icon: Icons.warning,
    ),
    SlideInfo(
      title: "Protege el Ambiente",
      description:
          "Reporta amenazas ambientales directamente a las autoridades",
      icon: Icons.security,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkUser();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _startAutoPlay(delay: const Duration(seconds: 10));
  }

  void _startAutoPlay({Duration delay = const Duration(seconds: 3)}) {
    _timer = Timer(delay, () {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!_isUserInteracting && mounted) {
          if (activeIndex < slides.length - 1) {
            controller.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            controller.animateToPage(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppColors.primaryGreenDark),
              Color(AppColors.primaryGreen),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 40),
              SizedBox(
                height: 400,
                child: GestureDetector(
                  onPanDown: (_) {
                    _isUserInteracting = true;
                  },
                  onPanEnd: (_) {
                    _isUserInteracting = false;
                    _resetTimer();
                  },
                  child: PageView.builder(
                    controller: controller,
                    itemCount: slides.length,
                    onPageChanged: (index) =>
                        setState(() => activeIndex = index),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => buildSlide(slides[index]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildIndicator(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          LoginBottomSheet.show(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppColors.primaryGreen),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          RegistroBottomSheet.show(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '© CentroGeo 2024',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIndicator() {
    return AnimatedSmoothIndicator(
      activeIndex: activeIndex,
      count: slides.length,
      effect: ExpandingDotsEffect(
        dotWidth: 8,
        dotHeight: 8,
        activeDotColor: Colors.white,
        dotColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget buildSlide(SlideInfo slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 100,
            color: const Color(0xFF34A853),
          ),
          const SizedBox(height: 20),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SlideInfo {
  final String title;
  final String description;
  final IconData icon;

  SlideInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}
