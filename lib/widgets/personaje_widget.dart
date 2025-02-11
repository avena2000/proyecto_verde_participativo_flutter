import 'package:flutter/material.dart';
import '../models/accesorio_config.dart';

class PersonajeWidget extends StatelessWidget {
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;


  const PersonajeWidget({
    super.key,
    this.cabello = 'default',
    this.vestimenta = 'default',
    this.barba = '0',
    this.detalleFacial = '0',
    this.detalleAdicional = '0',
  });

  Widget _buildAccesorio(BuildContext context, String tipo, String nombre, Map<String, AccesorioConfig> configs) {

    if (nombre == '0') {
          return Container(); // Devuelve un contenedor vacío
    }

    final config = configs[nombre] ?? configs['default']!;

    return Positioned(
      bottom: MediaQuery.of(context).size.height * config.bottomOffset,
      left: config.leftOffset,
      right: config.rightOffset,
      child: Container(
        height: MediaQuery.of(context).size.height * config.heightFactor,
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
    return Stack(
      children: [
        // Personaje base
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.47,
          left: 0,
          right: 4,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/personaje_base.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Accesorios
        _buildAccesorio(context, 'detalle_facial', detalleFacial, AccesorioConfig.detalleFacialConfigs),
        _buildAccesorio(context, 'detalle_adicional', detalleAdicional, AccesorioConfig.detalleAdicionalConfigs),
        _buildAccesorio(context, 'vestimenta', vestimenta, AccesorioConfig.vestimentaConfigs),
        _buildAccesorio(context, 'barba', barba, AccesorioConfig.barbaConfigs),
        _buildAccesorio(context, 'cabello', cabello, AccesorioConfig.cabelloConfigs),

      ],
    );
  }

}