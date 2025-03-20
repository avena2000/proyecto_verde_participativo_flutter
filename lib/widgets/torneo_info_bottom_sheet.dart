import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/models/torneo.dart';
import 'package:proyecto_verde_participativo/services/api_service.dart';
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TorneoInfoBottomSheet extends StatefulWidget {
  final String torneoId;
  final Function onTorneoAbandonado;

  const TorneoInfoBottomSheet({
    Key? key,
    required this.torneoId,
    required this.onTorneoAbandonado,
  }) : super(key: key);

  @override
  State<TorneoInfoBottomSheet> createState() => _TorneoInfoBottomSheetState();
}

class _TorneoInfoBottomSheetState extends State<TorneoInfoBottomSheet> {
  final ApiService _apiService = ApiService();
  final notificationService = NotificationService();
  bool _isLoading = true;
  Torneo? _torneo;
  bool? _esEquipoA;

  @override
  void initState() {
    super.initState();
    _cargarDatosTorneo();
  }

  Future<void> _cargarDatosTorneo() async {
    try {
      setState(() => _isLoading = true);

      // Obtener datos del torneo
      final torneo = await _apiService.get(
        '/torneos/${widget.torneoId}',
        parser: (data) => Torneo.fromJson(data),
      );

      // Obtener información sobre el equipo del usuario en el torneo
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final equipoInfo = await _apiService.get(
          '/torneos/${widget.torneoId}/usuario/$userId/equipo',
          parser: (data) => data['equipo'] as bool,
        );

        setState(() {
          _torneo = torneo;
          _esEquipoA = equipoInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      notificationService.showError(
          context, "No se pudo cargar la información del torneo");
    }
  }

  Future<void> _mostrarConfirmacionSalida() async {
    HapticFeedback.mediumImpact();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text(
            'Si abandonas el torneo, tu equipo perderá los puntos que has aportado. Esta acción no se puede deshacer.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Abandonar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _abandonarTorneo();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _abandonarTorneo() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        _apiService.setContext(context);
        await _apiService.delete(
          '/torneos/${widget.torneoId}/usuario/$userId',
          showMessages: true,
        );

        notificationService.showSuccess(
            context, "Has abandonado el torneo exitosamente");

        // Actualizar SharedPreferences
        await prefs.setString('torneo', '');

        // Notificar que el torneo fue abandonado
        widget.onTorneoAbandonado();

        // Cerrar el bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      notificationService.showError(
          context, "No se pudo abandonar el torneo. Inténtalo de nuevo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Información del Torneo',
              style: TextStyle(
                fontFamily: 'YesevaOne',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else if (_torneo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _torneo!.nombre,
                    style: const TextStyle(
                      fontFamily: 'YesevaOne',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${_torneo!.finalizado ? 'Finalizado' : 'Activo'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modalidad: ${_torneo!.modalidad}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha inicio: ${_torneo!.fechaInicio.day}/${_torneo!.fechaInicio.month}/${_torneo!.fechaInicio.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha fin: ${_torneo!.fechaFin.day}/${_torneo!.fechaFin.month}/${_torneo!.fechaFin.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),

                  // Si es modalidad versus, mostrar el equipo del usuario
                  if (_torneo?.modalidad.toLowerCase() == 'versus' &&
                      _esEquipoA != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perteneces al equipo: ${_esEquipoA! ? _torneo!.nombreUbicacionA : _torneo!.nombreUbicacionB}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (!_isLoading && _torneo != null && !_torneo!.finalizado)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _mostrarConfirmacionSalida,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Abandonar torneo',
                  style: TextStyle(
                    fontFamily: 'YesevaOne',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
