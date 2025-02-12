import 'package:flutter/material.dart';
import 'package:proyecto_verde_participativo/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../models/user_action.dart';
import '../providers/acciones_provider.dart';
import '../widgets/fullscreen_image_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class MisAcciones extends StatefulWidget {
  const MisAcciones({super.key});

  @override
  State<MisAcciones> createState() => _MisAccionesState();
}

class _MisAccionesState extends State<MisAcciones> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      context.read<AccionesProvider>().fetchAcciones(userId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Container(
        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Center(
              child: Text(
                'Mis Acciones',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AccionesProvider>(
                builder: (context, accionesProvider, child) {
                  if (accionesProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (accionesProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error al cargar las acciones',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  if (accionesProvider.acciones.isEmpty) {
                    return Center(
                      child: Text(
                        'No has registrado acciones aún',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: accionesProvider.acciones.length,
                    itemBuilder: (context, index) {
                      final accion = accionesProvider.acciones[index];
                      return _buildAccionCard(accion);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionCard(UserAction accion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    final acciones = context.read<AccionesProvider>().acciones;
                    final index = acciones.indexOf(accion);
                    Navigator.of(context).push(BottomSheetTransition(
                      page: FullscreenImageGallery(
                        acciones: acciones,
                        initialIndex: index,
                      ),
                    ));
                  },
                  child: Hero(
                    tag:
                        'image_${context.read<AccionesProvider>().acciones.indexOf(accion)}',
                    child: CachedNetworkImage(
                      fadeInDuration: const Duration(milliseconds: 200),
                      imageUrl: accion.foto,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getColorForTipoAccion(accion.tipoAccion),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      accion.tipoAccion.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'YesevaOne',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accion.lugar,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForTipoAccion(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
        return Color.fromARGB(255, 163, 18, 18);
      case 'descubrimiento':
        return Color.fromARGB(255, 5, 119, 64);
      case 'ayuda':
        return Color.fromARGB(255, 16, 116, 33);
      default:
        return Color(AppColors.primaryGreen);
    }
  }
}
