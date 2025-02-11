import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:proyecto_verde_participativo/services/notification_service.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/acciones_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubirAccionPage extends StatefulWidget {
  const SubirAccionPage({super.key});

  @override
  State<SubirAccionPage> createState() => _SubirAccionPageState();
}

class _SubirAccionPageState extends State<SubirAccionPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  final NotificationService notificationService = NotificationService();
  late final AnimationController _dragAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  
  int _currentPage = 0;
  double _verticalDragStart = 0;
  bool _isDraggingVertically = false;
  double _dragProgress = 0.0;
  double _lastHapticProgress = 0.0;
  File? _image;

  Position? _currentPosition;
  bool _isCompressing = false;
  

  final List<String> imagenes = [
    'assets/acciones/accion_descubrimiento.png',
    'assets/acciones/accion_alerta.png',
    'assets/acciones/accion_ayuda.png',
  ];

  final List<String> titulos = [
    'Acción de\nDescubrimiento',
    'Acción de\nAlerta',
    'Acción de\nAyuda',
  ];

  final List<String> titulosSinSalto = [
    'Descubrimiento',
    'Alerta',
    'Ayuda',
  ];

  final List<String> descripciones = [
    '\nDescubre algo nuevo y compártelo con la comunidad.\n\nEsto puede ser una planta, un animal, un fenómeno natural...',
    '\nAlerta de una situación peligrosa.\n\nEsto puede ser un incendio, un accidente, una plaga...',
    '\nAyuda en tu entorno.\n\nEsto puede ser limpiar un espacio, ayudar a un animal herido...',
  ];


  final List<Color> colores = [
    const Color(0xB8057740),
    const Color(0xB8B14A2B),
    const Color(0xB8107420),
  ];

  void _handleVerticalDragStart(DragStartDetails details) {
    _verticalDragStart = details.globalPosition.dy;
    _isDraggingVertically = true;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingVertically) return;

    final currentPosition = details.globalPosition.dy;
    final dragDistance = _verticalDragStart - currentPosition;
    final screenHeight = MediaQuery.of(context).size.height;
    final newProgress = (dragDistance / (screenHeight * 0.25)).clamp(0.0, 1.0);

    // Proporcionar feedback háptico cada 25% del progreso
    if ((newProgress - _lastHapticProgress).abs() >= 0.1) {
      HapticFeedback.lightImpact();
      _lastHapticProgress = newProgress;
    }

    setState(() {
      _dragProgress = newProgress;
    });
 
    // Si el deslizamiento hacia arriba es mayor al 20% de la altura de la pantalla
    if (dragDistance > screenHeight * 0.25) {
      _isDraggingVertically = false;
      _abrirCamara();
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _isDraggingVertically = false;
    _lastHapticProgress = 0.0;

    final currentProgress = _dragProgress;

    // Animamos directamente desde el valor actual hasta 0
    _dragAnimationController.value = currentProgress;
    _dragAnimationController.animateTo(0.0,
      curve: Curves.easeOutCubic,
      duration: Duration(milliseconds: (300 * currentProgress).round()),
    ).whenComplete(() {
      setState(() {
        _dragProgress = 0.0;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _dragAnimationController.addListener(() {
      setState(() {
        _dragProgress = _dragAnimationController.value;
      });
    });
    _pageController.addListener(() {
      int next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final permiso = await Permission.location.request();
      if (permiso.isGranted) {
        Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        ).then((position) {
          setState(() {
            _currentPosition = position;
          });
          developer.log('Ubicación actual: Lat: ${position.latitude}, Long: ${position.longitude}');
        }).catchError((e) {
          developer.log('Error al obtener ubicación: $e');
        });
      } else {
        developer.log('Permiso de ubicación denegado');
      }
    } catch (e) {
      developer.log('Error al solicitar permiso de ubicación: $e');
    }
  }

  // Función estática para procesar la imagen en segundo plano
  static Future<Uint8List?> _procesarImagenEnBackground(List<dynamic> args) async {
    try {
      final Uint8List imageBytes = args[0];
      final int quality = args[1];

      // Decodificar la imagen
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        // Redimensionar si la imagen es muy grande
        img.Image resizedImage = originalImage;
        if (originalImage.width > 1920) {
          resizedImage = img.copyResize(
            originalImage,
            width: 1920,
            interpolation: img.Interpolation.average,
          );
        }

        // Comprimir la imagen y retornar los bytes
        return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
      }
      return null;
    } catch (e) {
      developer.log('Error en procesamiento background: $e');
      return null;
    }
  }

  Future<void> _abrirCamara() async {
    try {
      _obtenerUbicacion();

      final permiso = await Permission.camera.request();
      if (permiso.isGranted) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        
        if (photo != null) {
          setState(() {
            _isCompressing = true;
          });

          try {
            // Leer la imagen como bytes
            final Uint8List imageBytes = await photo.readAsBytes();
            
            // Procesar en segundo plano
            final Uint8List? compressedBytes = await compute(
              _procesarImagenEnBackground, 
              [imageBytes, 85]
            );

            if (compressedBytes != null) {
              // Guardar el resultado
              final directory = await getApplicationDocumentsDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final tempPath = '${directory.path}/compressed_image_$timestamp.jpg';
              
              final compressedFile = File(tempPath);
              await compressedFile.writeAsBytes(compressedBytes);

              // Eliminar imagen anterior si existe
              if (_image != null && await _image!.exists()) {
                try {
                  await _image!.delete();
                } catch (e) {
                  developer.log('Error al eliminar imagen anterior: $e');
                }
              }

              setState(() {
                _image = compressedFile;
                _isCompressing = false;
              });

              _mostrarDialogoConfirmacion();
            } else {
              throw Exception('Error al procesar la imagen');
            }
          } catch (e) {
            developer.log('Error al comprimir la imagen: $e');
            setState(() {
              _image = File(photo.path);
              _isCompressing = false;
            });
            _mostrarDialogoConfirmacion();
          }
        }
      } else {
        developer.log('Permiso de cámara denegado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesita permiso para usar la cámara')),
        );
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      developer.log('Error al abrir la cámara: $e');
    }
  }

  void _mostrarDialogoConfirmacion() {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Acción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_image != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('¿Deseas subir esta foto como Acción de ${['Descubrimiento', 'Alerta', 'Ayuda'][_currentPage]}?'),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _image = null;
                });
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _subirAccion();
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _subirAccion() async {
    if (_image != null) {
      final accionesProvider = Provider.of<AccionesProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        notificationService.showError(
          context,
          'Error: Usuario no identificado',
        );
        return;
      }


      try {
        await accionesProvider.subirAccion(
          userId: userId,
          tipo: ['descubrimiento', 'alerta', 'ayuda'][_currentPage],
          imagePath: _image!.path,
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
        
        notificationService.showSuccess(
          context,
          'Acción subida correctamente',
        );
        
        setState(() {
          _image = null;
        });
        
        Navigator.of(context).pop();
      } catch (e) {
        notificationService.showError(
          context,
          'Error al subir la acción: ${e.toString()}',
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final animationOffset = screenHeight * 0.3 * _dragProgress;
    final scale = 1 + (_dragProgress * 0.2);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onVerticalDragStart: _handleVerticalDragStart,
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    HapticFeedback.lightImpact();
                  },
                  itemCount: imagenes.length,
                  itemBuilder: (context, index) {
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(imagenes[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -animationOffset,
                      left: 0,
                      right: 0,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              colores[_currentPage],
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: (screenHeight * 0.20) - animationOffset,
                      left: 0,
                      right: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          titulos[_currentPage],
                          key: ValueKey<String>(titulos[_currentPage]),
                          style: const TextStyle(
                            fontFamily: 'YesevaOne',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: (screenHeight * 0.17) - animationOffset,
                      left: 0,
                      right: 0,
                      child: Center(

                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: imagenes.length,
                          effect: ExpandingDotsEffect(
                            dotColor: Colors.white.withOpacity(0.4),
                            activeDotColor: Colors.white,
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 3,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: (screenHeight * 0.10) - animationOffset,
                      left: 0,
                      right: 0,
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      bottom: (screenHeight * 0.05) - animationOffset,
                      left: 0,
                      right: 0,
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.info, color: Colors.white),
                    onPressed: () {
                      // Aquí puedes agregar la lógica para mostrar información
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: 
                            Text(titulosSinSalto[_currentPage], textAlign: TextAlign.center, style: TextStyle(fontFamily: 'YesevaOne',fontSize: 24, fontWeight: FontWeight.bold),),
                            content: Text(descripciones[_currentPage], textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          );
                        },
                      );
                    },

                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (_isCompressing)
          Container(
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Procesando imagen...',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      fontFamily: 'YesevaOne',
                      fontWeight: FontWeight.normal,
                      fontSize: 24,
                    ),


                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}