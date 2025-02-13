import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_verde_participativo/models/user_profile.dart';
import 'package:proyecto_verde_participativo/models/user_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../providers/personaje_provider.dart';
import '../services/api_service.dart';
import '../widgets/configuracion_bottom_sheet.dart';
import 'medallas_page.dart';
import 'acciones_page.dart';
import 'accesorios_page.dart';
import 'subir_accion_page.dart';
import '../widgets/personaje_widget.dart';
import 'welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final GlobalKey<_HomePageState> homeKey = GlobalKey<_HomePageState>();

  @override
  State<HomePage> createState() => _HomePageState();

  static Future<void> actualizarEstadisticas(BuildContext context) async {
    final homeState = homeKey.currentState;
    if (homeState != null) {
      await homeState._actualizarDatosDesdeAPI();
    }
  }
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _nombre = '';
  String _apellido = '';
  String _frase = '';
  int _acciones = 0;
  int _puntos = 0;
  int _amigos = 0;
  int _torneos = 0;
  bool _isLoading = true;

  // Variables para la animación
  late AnimationController _animationController;

  Timer? _hapticTimer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _cargarDatosIniciales();
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _animateValue(
    int localValue,
    int apiValue,
    AnimationController controller,
    void Function(int) onUpdate,
  ) {
    if (apiValue == localValue) {
      onUpdate(apiValue);
      return;
    }

    _isAnimating = true;
    controller.duration = const Duration(milliseconds: 1500);

    Animation<int> animation = IntTween(
      begin: localValue,
      end: apiValue,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    animation.addListener(() {
      onUpdate(animation.value);
    });

    // Configurar el timer para la retroalimentación háptica
    const hapticInterval = Duration(milliseconds: 100);
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(hapticInterval, (timer) {
      if (_isAnimating) {
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
      }
    });

    controller.forward(from: 0).whenComplete(() {
      _isAnimating = false;
      _hapticTimer?.cancel();
    });
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = false);
    // Primero cargamos los datos de SharedPreferences para mostrar algo rápido
    await _cargarDatosLocales();
    // Luego actualizamos con datos frescos de la API
    await _actualizarDatosDesdeAPI();

    setState(() => _isLoading = false);
  }

  Future<void> _cargarDatosLocales() async {
    final prefs = await SharedPreferences.getInstance();
    final personajeProvider =
        Provider.of<PersonajeProvider>(context, listen: false);

    setState(() {
      _frase = prefs.getString('slogan') ?? '';
      _nombre = prefs.getString('nombre') ?? '';
      _apellido = prefs.getString('apellido') ?? '';
      _acciones = prefs.getInt('acciones') ?? 0;
      _puntos = prefs.getInt('puntos') ?? 0;
      _amigos = prefs.getInt('amigos') ?? 0;
      _torneos = prefs.getInt('torneos') ?? 0;
    });

    // Cargar datos del personaje usando el provider
    await personajeProvider.cargarDatosLocales();
  }

  Future<void> _actualizarDatosDesdeAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final personajeProvider =
          Provider.of<PersonajeProvider>(context, listen: false);

      if (userId == null) return;

      final userStats = await _apiService.get(
        '/users/$userId/stats',
        parser: (data) => UserStats.fromJson(data),
      );

      final userProfile = await _apiService.get(
        '/users/$userId/profile',
        parser: (data) => UserProfile.fromJson(data),
      );

      // Guardar los valores actuales como locales
      final localAcciones = _acciones;
      final localPuntos = _puntos;
      final localAmigos = _amigos;
      final localTorneos = _torneos;

      // Actualizamos SharedPreferences con los nuevos datos
      await prefs.setInt('acciones', userStats.acciones);
      await prefs.setInt('puntos', userStats.puntos);
      await prefs.setInt('amigos', userStats.cantidadAmigos);
      await prefs.setInt('torneos', userStats.torneosParticipados);
      await prefs.setInt('victoriaTorneos', userStats.torneosGanados);
      await prefs.setString('slogan', userProfile.slogan);

      // Actualizamos el personaje usando el provider
      personajeProvider.actualizarAccesorios(
        cabello: userProfile.cabello,
        vestimenta: userProfile.vestimenta,
        barba: userProfile.barba,
        detalleFacial: userProfile.detalleFacial,
        detalleAdicional: userProfile.detalleAdicional,
      );

      // Animamos los valores si hay diferencias
      if (mounted) {
        // Reiniciamos el controlador de animación si está en uso
        if (_animationController.isAnimating) {
          _animationController.stop();
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if (localAcciones != userStats.acciones) {
            _animateValue(
              localAcciones,
              userStats.acciones,
              _animationController,
              (value) => setState(() => _acciones = value),
            );
          }

          if (localPuntos != userStats.puntos) {
            _animateValue(
              localPuntos,
              userStats.puntos,
              _animationController,
              (value) => setState(() => _puntos = value),
            );
          }

          if (localAmigos != userStats.cantidadAmigos) {
            _animateValue(
              localAmigos,
              userStats.cantidadAmigos,
              _animationController,
              (value) => setState(() => _amigos = value),
            );
          }

          if (localTorneos != userStats.torneosParticipados) {
            _animateValue(
              localTorneos,
              userStats.torneosParticipados,
              _animationController,
              (value) => setState(() => _torneos = value),
            );
          }
        });

        setState(() {
          _frase = userProfile.slogan;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de la API: $e');
    }
  }

  void _mostrarConfiguracion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(AppColors.darkGreen),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(27),
            topRight: Radius.circular(27),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: ConfiguracionBottomSheet(
            onLogout: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomePage()),
                (route) => false,
              );
            },
            onUpdateComplete: () {
              _cargarDatosIniciales();
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hapticTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
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
            Consumer<PersonajeProvider>(
              builder: (context, personajeProvider, child) => PersonajeWidget(
                cabello: personajeProvider.cabello,
                vestimenta: personajeProvider.vestimenta,
                barba: personajeProvider.barba,
                detalleFacial: personajeProvider.detalleFacial,
                detalleAdicional: personajeProvider.detalleAdicional,
              ),
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
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _mostrarConfiguracion,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
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
                                isAddition: true,
                                color: Colors.yellow,
                              ),
                              _buildStatistic(
                                icon: Icons.group_rounded,
                                value: _amigos.toString(),
                                isInverted: true,
                                isAddition: true,
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
          child: const MenuPrincipal(),
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
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    final homePageState = context.findAncestorStateOfType<_HomePageState>();
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
            title: 'Mis Medallas',
            subtitle: 'Revisa tus logros',
            onTap: () async {
              HapticFeedback.lightImpact();
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');
              if (userId != null) {
                showCustomBottomSheet(
                  context,
                  (scrollController) => MisMedallas(
                    userId: userId,
                    scrollController: scrollController,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            icon: Icons.eco_outlined,
            title: 'Mis Acciones',
            subtitle: 'Registro de tus acciones',
            onTap: () {
              HapticFeedback.lightImpact();
              showCustomBottomSheet(
                context,
                (scrollController) => MisAcciones(
                  scrollController: scrollController,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            icon: Icons.style_outlined,
            title: 'Accesorios',
            subtitle: 'Personaliza tu personaje',
            onTap: () {
              HapticFeedback.lightImpact();
              showCustomBottomSheet(
                context,
                (scrollController) => Accesorios(
                  scrollController: scrollController,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubirAccionPage(),
                    ),
                  ).then((_) {
                    // Actualizar datos cuando regrese de SubirAccionPage
                    if (homePageState != null) {
                      homePageState._cargarDatosIniciales();
                    }
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Subir Una Acción',
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
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
  Widget Function(ScrollController) contentBuilder,
) {
  final DraggableScrollableController draggableController =
      DraggableScrollableController();
  bool isClosed = false;

  showModalBottomSheet(
    context: context,
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
            initialChildSize: 0.6,
            minChildSize: 0.1,
            maxChildSize: 0.6,
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
