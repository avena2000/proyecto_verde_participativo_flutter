import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/accesorio_config.dart';
import 'package:provider/provider.dart';
import '../providers/personaje_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Accesorios extends StatefulWidget {
  const Accesorios({super.key});

  @override
  State<Accesorios> createState() => _AccesoriosState();
}

class _AccesoriosState extends State<Accesorios> {
  int _puntosUsuario = 0;

  @override
  void initState() {
    super.initState();
    _cargarPuntos();
  }

  Future<void> _cargarPuntos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _puntosUsuario = prefs.getInt('puntos') ?? 0;
    });
  }

  Widget _buildCategoriaAccesorios({
    required String titulo,
    required Map<String, AccesorioConfig> accesorios,
    required String selectedAccesorio,
    required Function(String) onAccesorioSelected,
    required String tipo,
  }) {
    // Filtrar el accesorio default
    final accesoriosSinDefault = Map<String, AccesorioConfig>.from(accesorios)
      ..removeWhere((key, value) => key == 'default');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'YesevaOne',
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: accesoriosSinDefault.length + 1, // +1 para la opción "nada"
            itemBuilder: (context, index) {
              if (index == 0) {
                // Opción "nada"
                final bool isSelected = selectedAccesorio == 'default' || selectedAccesorio == '0';
                final defaultConfig = accesorios['default'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildAccesorioCard(
                    nombre: 'Nada',
                    imagen: defaultConfig != null
                      ? 'assets/accesorios/$tipo/default.png'
                      : 'assets/accesorios/nada.png',
                    costo: 0,
                    isLocked: false,
                    isSelected: isSelected,
                    onTap: () {
                      if (accesoriosSinDefault.length == Map<String, AccesorioConfig>.from(accesorios).length) {
                        onAccesorioSelected('0');
                      } else {
                        onAccesorioSelected('default');
                      }
                    },
                    showEquipar: !isSelected,
                  ),
                );
              }

              final accesorio = accesoriosSinDefault.entries.elementAt(index - 1);
              final bool isSelected = selectedAccesorio == accesorio.key;
              final int costoPuntos = int.tryParse(accesorio.value.puntos) ?? 0;
              final bool isLocked = costoPuntos > _puntosUsuario;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _buildAccesorioCard(
                  nombre: accesorio.value.nombre,
                  imagen: 'assets/accesorios/$tipo/${accesorio.key}.png',
                  costo: costoPuntos,
                  isLocked: isLocked,
                  isSelected: isSelected,
                  onTap: () {
                    if (!isLocked) {
                      onAccesorioSelected(accesorio.key);
                    }
                  },
                  showEquipar: !isLocked && !isSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonajeProvider>(
      builder: (context, personajeProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Accesorios',
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
                child: ListView(
                  children: [
                    _buildCategoriaAccesorios(
                      titulo: 'Cabello',
                      accesorios: AccesorioConfig.cabelloConfigs,
                      selectedAccesorio: personajeProvider.cabello,
                      onAccesorioSelected: (value) => personajeProvider.setCabello(value),
                      tipo: 'cabello',
                    ),
                    _buildCategoriaAccesorios(
                      titulo: 'Vestimenta',
                      accesorios: AccesorioConfig.vestimentaConfigs,
                      selectedAccesorio: personajeProvider.vestimenta,
                      onAccesorioSelected: (value) => personajeProvider.setVestimenta(value),
                      tipo: 'vestimenta',
                    ),
                    _buildCategoriaAccesorios(
                      titulo: 'Barba',
                      accesorios: AccesorioConfig.barbaConfigs,
                      selectedAccesorio: personajeProvider.barba,
                      onAccesorioSelected: (value) => personajeProvider.setBarba(value),
                      tipo: 'barba',
                    ),
                    _buildCategoriaAccesorios(
                      titulo: 'Detalle Facial',
                      accesorios: AccesorioConfig.detalleFacialConfigs,
                      selectedAccesorio: personajeProvider.detalleFacial,
                      onAccesorioSelected: (value) => personajeProvider.setDetalleFacial(value),
                      tipo: 'detalle_facial',
                    ),
                    _buildCategoriaAccesorios(
                      titulo: 'Detalle Adicional',
                      accesorios: AccesorioConfig.detalleAdicionalConfigs,
                      selectedAccesorio: personajeProvider.detalleAdicional,
                      onAccesorioSelected: (value) => personajeProvider.setDetalleAdicional(value),
                      tipo: 'detalle_adicional',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccesorioCard({
    required String nombre,
    required String imagen,
    required int costo,
    required bool isLocked,
    required bool isSelected,
    required VoidCallback onTap,
    required bool showEquipar,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: isSelected 
              ? Color(AppColors.primaryGreen).withOpacity(0.2)
              : Colors.white.withOpacity(isLocked ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                ? Color(AppColors.primaryGreen)
                : Colors.white.withOpacity(isLocked ? 0.1 : 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLocked 
                        ? Colors.white.withOpacity(0.05)
                        : Color(AppColors.primaryGreen).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: nombre == 'Nada'
                              ? (imagen.contains('default.png')
                                  ? Image.asset(
                                      imagen,
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.not_interested,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 32,
                                    ))
                              : Image.asset(
                                  imagen,
                                  fit: BoxFit.contain,
                                  color: isLocked ? Colors.black.withOpacity(0.8) : null,
                                  colorBlendMode: isLocked ? BlendMode.srcATop : null,
                                ),
                        ),
                        if (isLocked)
                          Center(
                            child: Icon(
                              Icons.lock,
                              color: Colors.white.withOpacity(0.3),
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isLocked)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.eco,
                        color: Color(AppColors.primaryGreen).withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        costo.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    ),
                  ],
                )
                else if (showEquipar)

                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Equipar',
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                  ],
                )
              ],
            ),
          ),

        ),
      ),
    );

  }
}