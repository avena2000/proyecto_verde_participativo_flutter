import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/models/user_basic_info.dart';
import 'package:proyecto_verde_participativo/models/user_profile.dart';
import 'package:proyecto_verde_participativo/models/user_stats.dart';
import 'package:proyecto_verde_participativo/screens/amigos_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'medallas_page.dart';
import 'acciones_page.dart';
import 'accesorios_page.dart';
import '../widgets/personaje_widget.dart';

class HomePageFriend extends StatefulWidget {
  final String amigoId;

  const HomePageFriend({super.key, required this.amigoId});

  @override
  State<HomePageFriend> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageFriend>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late String amigoId;

  String _nombre = '';
  String _apellido = '';
  String _frase = '';
  String _cabello = 'default';
  String _vestimenta = 'default';
  String _barba = '0';
  String _detalleFacial = '0';
  String _detalleAdicional = '0';
  int _acciones = 0;
  int _puntos = 0;
  int _amigos = 0;
  int _torneos = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setFullScreenMode();
    _initializeControllers();
    amigoId = widget.amigoId; // Asignamos el valor de widget.amigoId al state
    _cargarDatosIniciales(); // Llamar a una función para cargar datos del amigo
  }

  void _setFullScreenMode() {
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
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  // Variables para la animación
  late AnimationController _animationController;

  Timer? _hapticTimer;

  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = false);

    // Luego actualizamos con datos frescos de la API
    await _actualizarDatosDesdeAPI();

    setState(() => _isLoading = false);
  }

  Future<void> _actualizarDatosDesdeAPI() async {
    try {
      final userStats = await _apiService.get(
        '/users/$amigoId/stats',
        parser: (data) => UserStats.fromJson(data),
      );

      final userProfile = await _apiService.get(
        '/users/$amigoId/profile',
        parser: (data) => UserProfile.fromJson(data),
      );

      final userBasic = await _apiService.get(
        '/users/$amigoId/basic-info',
        parser: (data) => UserBasicInfo.fromJson(data),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('friend-slogan', userProfile.slogan);
      await prefs.setString('friend-cabello', userProfile.cabello);
      await prefs.setString('friend-vestimenta', userProfile.vestimenta);
      await prefs.setString('friend-barba', userProfile.barba);
      await prefs.setString('friend-detalleFacial', userProfile.detalleFacial);
      await prefs.setString(
          'friend-detalleAdicional', userProfile.detalleAdicional);
      await prefs.setInt('friend-acciones', userStats.acciones);
      await prefs.setInt('friend-puntos', userStats.puntos);
      await prefs.setInt('friend-cantidadAmigos', userStats.cantidadAmigos);
      await prefs.setInt(
          'friend-torneosParticipados', userStats.torneosParticipados);
      await prefs.setInt('friend-torneosGanados', userStats.torneosGanados);
      await prefs.setString('friend-nombre', userBasic.nombre);
      await prefs.setString('friend-apellido', userBasic.apellido);

      setState(() {
        _frase = userProfile.slogan;
        _cabello = userProfile.cabello;
        _vestimenta = userProfile.vestimenta;
        _barba = userProfile.barba;
        _detalleFacial = userProfile.detalleFacial;
        _detalleAdicional = userProfile.detalleAdicional;
        _acciones = userStats.acciones;
        _puntos = userStats.puntos;
        _amigos = userStats.cantidadAmigos;
        _torneos = userStats.torneosParticipados;
        _nombre = userBasic.nombre;
        _apellido = userBasic.apellido;
      });
    } catch (e) {
      debugPrint('Error al cargar datos de la API: $e');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hapticTimer?.cancel();
    _setFullScreenMode(); // Mantener el modo de pantalla completa al cerrar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
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
        child: Stack(
          children: [
            PersonajeWidget(
              cabello: _cabello,
              vestimenta: _vestimenta,
              barba: _barba,
              detalleFacial: _detalleFacial,
              detalleAdicional: _detalleAdicional,
              isPrincipal: true,
              onDoubleTap: () {
                HapticFeedback.lightImpact();
                showCustomBottomSheet(
                  context,
                  (scrollController) => Accesorios(
                    scrollController: scrollController,
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 175,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(AppColors.darkGreen).withOpacity(0.8),
                      Color(AppColors.darkGreen).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 12.0,
                      bottom: 0,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.white)
                        else ...[
                          Text(
                            '$_nombre $_apellido',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'YesevaOne',
                                overflow: TextOverflow.ellipsis,
                                color: Colors.white),
                          ),
                          Text(
                            _frase,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 100),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatistic(
                                icon: Icons.photo_camera_rounded,
                                value: _acciones.toString(),
                                isInverted: false,
                                isAddition: false,
                                color: Colors.white,
                              ),
                              _buildStatistic(
                                icon: Icons.eco_rounded,
                                value: _puntos.toString(),
                                isInverted: true,
                                isAddition: false,
                                color: Color(AppColors.primaryGreen),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatistic(
                                icon: Icons.emoji_events_rounded,
                                value: _torneos.toString(),
                                isInverted: false,
                                isAddition: false,
                                color: Colors.yellow,
                              ),
                              _buildStatistic(
                                icon: Icons.group_rounded,
                                value: _amigos.toString(),
                                isInverted: true,
                                isAddition: false,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Material(
        color: Color(AppColors.transparent),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
              color: Color(AppColors.darkGreen),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(27),
                topRight: Radius.circular(27),
              )),
          child: MenuPrincipal(
            pendingCount: 0,
            amigoId: amigoId,
          ),
        ),
      ),
    );
  }

  Widget _buildStatistic({
    required IconData icon,
    required String value,
    required bool isInverted,
    required bool isAddition,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          if (!isInverted) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                    if (isAddition) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add_circle,
                        color: color.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (isAddition) ...[
                      Icon(
                        Icons.add_circle,
                        color: color.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ],
      ),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({
    super.key,
    required this.pendingCount,
    required this.amigoId,
  });

  final int pendingCount;
  final String amigoId;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Menú Principal',
              style: TextStyle(
                fontFamily: 'YesevaOne',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            icon: Icons.military_tech,
            title: 'Medallas',
            subtitle: 'Revisa sus logros',
            pendingCount: pendingCount,
            onTap: () async {
              HapticFeedback.lightImpact();
              showCustomBottomSheet(
                context,
                (scrollController) => MisMedallas(
                  userId: amigoId,
                  scrollController: scrollController,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            icon: Icons.eco_outlined,
            title: 'Acciones',
            subtitle: 'Registro de sus acciones',
            pendingCount: 0,
            onTap: () {
              HapticFeedback.lightImpact();
              showCustomBottomSheet(
                context,
                (scrollController) => MisAcciones(
                  userId: amigoId,
                  scrollController: scrollController,
                ),
              );
            },
          ),
          const Expanded(child: SizedBox(width: 100)),
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
                  color: Color(AppColors.primaryGreen).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Volver',
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int pendingCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'YesevaOne',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        pendingCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomBottomSheet(
  BuildContext context,
  Widget Function(ScrollController) contentBuilder, {
  bool canExpand = false,
}) {
  final DraggableScrollableController draggableController =
      DraggableScrollableController();
  bool isClosed = false;

  showModalBottomSheet(
    context: context,
    useSafeArea: canExpand,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              color: Colors.transparent,
            ),
          ),
          DraggableScrollableSheet(
            controller: draggableController,
            initialChildSize: !canExpand ? 0.6 : 0.64,
            minChildSize: 0.1,
            maxChildSize: !canExpand ? 0.6 : 1,
            snap: true,
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) {
              // Agregar un listener para cerrar cuando la altura sea menor a 0.2
              draggableController.addListener(() {
                if (draggableController.size <= 0.2) {
                  if (!isClosed) {
                    isClosed = true;
                    Navigator.pop(context);
                  }
                }
              });

              return Container(
                decoration: BoxDecoration(
                  color: Color(AppColors.darkGreen),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(27),
                    topRight: Radius.circular(27),
                  ),
                ),
                child: contentBuilder(scrollController),
              );
            },
          ),
        ],
      );
    },
  );
}
