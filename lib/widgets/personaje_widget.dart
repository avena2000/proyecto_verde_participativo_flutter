import 'package:flutter/material.dart';
import '../models/accesorio_config.dart';

class PersonajeWidget extends StatelessWidget {
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;
  final VoidCallback? onDoubleTap;
  final bool isPrincipal;
  final double height;

  const PersonajeWidget({
    super.key,
    this.cabello = 'default',
    this.vestimenta = 'default',
    this.barba = '0',
    this.detalleFacial = '0',
    this.detalleAdicional = '0',
    this.onDoubleTap,
    this.isPrincipal = true,
    this.height = 0,
  });

  Widget _buildAccesorio(BuildContext context, String tipo, String nombre,
      Map<String, AccesorioConfig> configs) {
    if (nombre == '0') {
      return Container(); // Devuelve un contenedor vacío
    }

    final config = configs[nombre] ?? configs['default']!;
    return Positioned(
      bottom: isPrincipal
          ? MediaQuery.of(context).size.height * config.bottomOffset
          : (height) * (config.bottomOffset),
      left: config.leftOffset,
      right: config.rightOffset,
      child: Container(
        height: isPrincipal
            ? MediaQuery.of(context).size.height * config.heightFactor
            : (config.heightFactor) * (height),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/accesorios/$tipo/$nombre.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Stack(
          children: [
          // Personaje base
          Positioned(
            bottom: isPrincipal ? MediaQuery.of(context).size.height * 0.47 : 0,
            left: 0,
            right: isPrincipal ? 4 : 0,
            child: Container(
              height: isPrincipal
                  ? MediaQuery.of(context).size.height * 0.55
                  : height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/personaje_base.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Accesorios
          _buildAccesorio(context, 'detalle_facial', detalleFacial,
              isPrincipal ? AccesorioConfig.detalleFacialConfigs : AccesorioConfig.detalleFacialConfigsNormalizados),
          _buildAccesorio(context, 'detalle_adicional', detalleAdicional,
              isPrincipal ? AccesorioConfig.detalleAdicionalConfigs : AccesorioConfig.detalleAdicionalConfigsNormalizados),
          _buildAccesorio(context, 'vestimenta', vestimenta,
              isPrincipal ? AccesorioConfig.vestimentaConfigs : AccesorioConfig.vestimentaConfigsNormalizados),
          _buildAccesorio(
              context, 'barba', barba, isPrincipal ? AccesorioConfig.barbaConfigs : AccesorioConfig.barbaConfigsNormalizados),
          _buildAccesorio(
              context, 'cabello', cabello, isPrincipal ? AccesorioConfig.cabelloConfigs : AccesorioConfig.cabelloConfigsNormalizados),
        ]));
  }
}
