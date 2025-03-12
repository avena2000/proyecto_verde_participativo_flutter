import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_animated/auto_animated.dart';
import '../constants/colors.dart';
import '../providers/medallas_provider.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class MisMedallas extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;

  const MisMedallas({
    super.key,
    required this.userId,
    required this.scrollController,
  });

  @override
  State<MisMedallas> createState() => _MisMedallasState();
}

class _MisMedallasState extends State<MisMedallas> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Establecer el contexto para las notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      // Llamar al API para resetear las medallas pendientes
      _resetPendingMedallas();
    });
  }

  Future<void> _resetPendingMedallas() async {
    try {
      await _apiService.resetPendingMedallas(widget.userId,
          showMessages: false);
    } catch (e) {
      // Manejar el error silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar el home page cuando se cierre el widget
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          await HomePage.actualizarEstadisticas(context);
        }
      },
      child: ChangeNotifierProvider(
        create: (_) => MedallasProvider()..cargarMedallas(widget.userId),
        child: _MedallasContent(scrollController: widget.scrollController),
      ),
    );
  }
}

class _MedallasContent extends StatelessWidget {
  final ScrollController scrollController;

  const _MedallasContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Mis Medallas',
              style: TextStyle(
                fontFamily: 'YesevaOne',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<MedallasProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (provider.error != null) {
                return Center(
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              return Expanded(
                child: LiveGrid.options(
                  controller: scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 32.0),
                  options: LiveOptions(
                    delay: Duration.zero,
                    showItemInterval: const Duration(milliseconds: 50),
                    showItemDuration: const Duration(milliseconds: 150),
                    visibleFraction: 0.001,
                    reAnimateOnVisibility: false,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: provider.medallas.length,
                  itemBuilder: (context, index, animation) {
                    final medalla = provider.medallas[index];
                    return FadeTransition(
                      opacity: Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuart,
                        )),
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.8,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          )),
                          child: _buildMedalCard(
                            title: medalla.nombre,
                            description: medalla.descripcion,
                            dificultad: medalla.dificultad,
                            icon: Icons.emoji_events_rounded,
                            isLocked: !medalla.desbloqueada,
                            progress: medalla.progreso,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedalCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isLocked,
    required double progress,
    required int dificultad,
  }) {
    Color color;
    if (dificultad == 1) {
      color = Colors.green;
    } else if (dificultad == 2) {
      color = Colors.yellow;
    } else if (dificultad == 3) {
      color = Colors.orange;
    } else if (dificultad == 4) {
      color = Colors.red;
    } else {
      color = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withOpacity(0.05)
                    : Color(AppColors.primaryGreen).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.white.withOpacity(0.3) : Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: Container()),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(isLocked ? 0.5 : 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'YesevaOne',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(isLocked ? 0.3 : 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(child: Container()), // Ocupa el espacio disponible
            SizedBox(
                height: 8), // Espacio entre el contenido y el último componente
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
