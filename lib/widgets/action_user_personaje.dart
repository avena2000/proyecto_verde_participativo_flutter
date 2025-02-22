import 'package:flutter/material.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/widgets/personaje_widget.dart';

class ActionUserPersonaje extends StatefulWidget {
  final String? userId;
  final double size;
  final String? cabello;
  final String? vestimenta;
  final String? barba;
  final String? detalleFacial;
  final String? detalleAdicional;

  const ActionUserPersonaje({
    super.key,
    this.userId,
    this.size = 60,
    this.cabello,
    this.vestimenta,
    this.barba,
    this.detalleFacial,
    this.detalleAdicional,
  }) : assert(
            userId != null ||
                (cabello != null &&
                    vestimenta != null &&
                    barba != null &&
                    detalleFacial != null &&
                    detalleAdicional != null),
            'Debes proporcionar un userId o todas las características del personaje');

  @override
  State<ActionUserPersonaje> createState() => _ActionUserPersonajeState();
}

class _ActionUserPersonajeState extends State<ActionUserPersonaje> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _cabello;
  String? _vestimenta;
  String? _barba;
  String? _detalleFacial;
  String? _detalleAdicional;

  @override
  void initState() {
    super.initState();
    if (widget.cabello != null) {
      _setLocalCharacteristics();
    } else {
      _cargarPersonaje();
    }
  }

  void _setLocalCharacteristics() {
    setState(() {
      _cabello = widget.cabello;
      _vestimenta = widget.vestimenta;
      _barba = widget.barba;
      _detalleFacial = widget.detalleFacial;
      _detalleAdicional = widget.detalleAdicional;
      _isLoading = false;
    });
  }

  Future<void> _cargarPersonaje() async {
    if (widget.userId == null) return;

    try {
      final userProfile = await _apiService.get(
        '/users/${widget.userId}/profile',
        parser: (data) => data,
      );

      if (mounted) {
        setState(() {
          _cabello = userProfile['cabello'];
          _vestimenta = userProfile['vestimenta'];
          _barba = userProfile['barba'];
          _detalleFacial = userProfile['detalle_facial'];
          _detalleAdicional = userProfile['detalle_adicional'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_cabello == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 300,
          height: 300,
          child: PersonajeWidget(
            cabello: _cabello!,
            vestimenta: _vestimenta!,
            barba: _barba!,
            detalleFacial: _detalleFacial!,
            detalleAdicional: _detalleAdicional!,
            isPrincipal: false,
            height: 300,
          ),
        ),
      ),
    );
  }
}
