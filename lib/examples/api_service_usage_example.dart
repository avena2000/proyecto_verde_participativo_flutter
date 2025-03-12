import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/accion.dart';

class ApiServiceUsageExample extends StatefulWidget {
  const ApiServiceUsageExample({Key? key}) : super(key: key);

  @override
  State<ApiServiceUsageExample> createState() => _ApiServiceUsageExampleState();
}

class _ApiServiceUsageExampleState extends State<ApiServiceUsageExample> {
  final ApiService _apiService = ApiService();
  List<Accion> _acciones = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Importante: establecer el contexto para mostrar notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      _loadAcciones();
    });
  }

  Future<void> _loadAcciones() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Usando el parámetro showMessages para mostrar notificaciones
      final acciones = await _apiService.getAcciones(showMessages: true);
      setState(() {
        _acciones = acciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _subirAccion() async {
    try {
      // Ejemplo de cómo subir una acción con notificaciones
      await _apiService.subirAccion(
        userId: '123',
        tipo: 'ayuda',
        imagePath: '/ruta/a/imagen.jpg',
        latitude: 19.4326,
        longitude: -99.1332,
        showMessages: true, // Mostrar notificaciones de éxito o error
      );

      // Recargar acciones después de subir una nueva
      _loadAcciones();
    } catch (e) {
      // El error ya se muestra en la notificación si showMessages es true
      // pero también podemos manejarlo aquí si es necesario
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de API Service'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAcciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _acciones.length,
                  itemBuilder: (context, index) {
                    final accion = _acciones[index];
                    return ListTile(
                      title: Text(accion.titulo),
                      subtitle: Text('Tipo: ${accion.tipo}'),
                      leading: CircleAvatar(
                        backgroundColor: accion.color,
                        child: const Icon(Icons.eco, color: Colors.white),
                      ),
                      trailing: Text('ID: ${accion.id}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _subirAccion,
        child: const Icon(Icons.add),
      ),
    );
  }
}
