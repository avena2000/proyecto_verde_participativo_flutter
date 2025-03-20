import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:proyecto_verde_participativo/main.dart';
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
import 'dart:async';

class SubirAccionPage extends StatefulWidget {
  const SubirAccionPage({super.key});

  @override
  State<SubirAccionPage> createState() => _SubirAccionPageState();
}

class _SubirAccionPageState extends State<SubirAccionPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  final NotificationService notificationService = NotificationService();
  late final AnimationController _dragAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  // Controlador para la animación de rebote
  late final AnimationController _bounceAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool ios = isIOS();
  // Animación de rebote usando un ciclo más natural
  late final Animation<double> _bounceAnimation = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.0, end: -30.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 1.0,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: -30.0, end: 0.0)
          .chain(CurveTween(curve: Curves.bounceOut)),
      weight: 1.0,
    ),
  ]).animate(_bounceAnimationController);

  int _currentPage = 0;
  double _verticalDragStart = 0;
  bool _isDraggingVertically = false;
  double _dragProgress = 0.0;
  double _lastHapticProgress = 0.0;
  File? _image;
  Uint8List? _webImageBytes; // Añadir para almacenar bytes de imagen en web

  // Variables para torneo
  bool _isTournamentValid = false;
  bool _hasTournamentLocation = false;
  double? _tournamentLatitude;
  double? _tournamentLongitude;
  double? _tournamentRadius;

  Position? _currentPosition;
  bool _isCompressing = false;
  bool _isUploading = false;
  bool _imagesPrecached = false;

  // Añadir variable para rastrear el estado de la ubicación
  bool _ubicacionEnProgreso = false;

  // Controlador de stream para notificar cambios en la ubicación
  final StreamController<bool> _ubicacionStreamController =
      StreamController<bool>.broadcast();
  StreamSubscription? _ubicacionSubscription;

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
    _bounceAnimationController.stop();
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

  void _startBounceAnimation() {
    _bounceAnimationController.forward().then((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDraggingVertically) {
            _bounceAnimationController.reset();
            _startBounceAnimation();
          }
        });
      }
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

    // Configurar el listener de la animación de rebote para forzar rebuild
    _bounceAnimationController.addListener(() {
      setState(() {});
    });

    // Iniciar la animación de rebote con un pequeño delay inicial
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !ios) {
        _startBounceAnimation();
      }
    });

    // Inicializar el stream de ubicación
    _ubicacionStreamController.stream.listen((_) {
      // Este stream se usará para notificar a los escuchadores cuando cambie el estado de ubicación
    });

    // Cargar datos del torneo
    _cargarDatosTorneo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      for (String imagen in imagenes) {
        precacheImage(AssetImage(imagen), context);
      }
      _imagesPrecached = true;
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      // Establecer el estado de carga para la ubicación
      setState(() {
        _ubicacionEnProgreso = true;
      });

      // Notificar que cambió el estado de ubicación
      _ubicacionStreamController.add(true);

      // Verificar el permiso de ubicación
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          // Permiso denegado
          if (mounted) {
            setState(() {
              _ubicacionEnProgreso = false;
            });
            _ubicacionStreamController.add(false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se requiere acceso a la ubicación para subir acciones. Por favor, activa la ubicación.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        // El usuario ha denegado permanentemente el permiso
        if (mounted) {
          setState(() {
            _ubicacionEnProgreso = false;
          });
          _ubicacionStreamController.add(false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se ha denegado permanentemente el permiso de ubicación. Por favor, actívalo en la configuración de tu dispositivo.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Usar un timeout para no bloquear demasiado tiempo en caso de problemas
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).then((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _ubicacionEnProgreso = false;
          });
          // Validar proximidad al torneo si hay ubicación de torneo
          if (_hasTournamentLocation) {
            _validarProximidadTorneo();
          }
          // Notificar que la ubicación ha cambiado
          _ubicacionStreamController.add(false);
          debugPrint(
              'Ubicación actual: Lat: ${position.latitude}, Long: ${position.longitude}');
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _ubicacionEnProgreso = false;
          });
          // Notificar que hubo un error
          _ubicacionStreamController.add(false);

          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al obtener ubicación: ${e.toString()}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        developer.log('Error al obtener ubicación: $e');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _ubicacionEnProgreso = false;
        });
        // Notificar que hubo un error
        _ubicacionStreamController.add(false);

        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      developer.log('Error al solicitar permiso de ubicación: $e');
    }
  }

  // Función estática para procesar la imagen en segundo plano
  static Future<Uint8List?> _procesarImagenEnBackground(
      List<dynamic> args) async {
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
        return Uint8List.fromList(
            img.encodeJpg(resizedImage, quality: quality));
      }
      return null;
    } catch (e) {
      developer.log('Error en procesamiento background: $e');
      return null;
    }
  }

  Future<void> _abrirCamara() async {
    // Iniciar obteniendo ubicación en segundo plano
    _obtenerUbicacion();

    try {
      // Abrir la cámara inmediatamente, sin esperar por la ubicación
      if (kIsWeb) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo != null) {
          setState(() {
            _isCompressing = true;
          });

          try {
            // Leer la imagen como bytes
            final Uint8List imageBytes = await photo.readAsBytes();

            // En web, no podemos usar compute, así que procesamos directamente
            _webImageBytes = imageBytes;
            _isCompressing = false;
            _mostrarDialogoConfirmacion();
          } catch (e) {
            developer.log('Error al comprimir la imagen: $e');
            // Para web, intentamos usar los bytes originales
            final Uint8List imageBytes = await photo.readAsBytes();
            setState(() {
              _webImageBytes = imageBytes;
              _isCompressing = false;
            });
            _mostrarDialogoConfirmacion();
          }
        }
      } else {
        // En móvil, solicitamos permisos para la cámara
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
              final Uint8List? compressedBytes =
                  await compute(_procesarImagenEnBackground, [imageBytes, 85]);

              if (compressedBytes != null) {
                // Guardar el resultado
                final directory = await getApplicationDocumentsDirectory();
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final tempPath =
                    '${directory.path}/compressed_image_$timestamp.jpg';

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
          } else {
            developer.log('Permiso de cámara denegado');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Se necesita permiso para usar la cámara')),
            );
          }
        }
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
        // Usar StatefulBuilder para poder actualizar el diálogo cuando cambia el estado
        return StatefulBuilder(builder: (context, setDialogState) {
          // Suscribirse al stream de ubicación para actualizar el diálogo
          _ubicacionSubscription?.cancel();
          _ubicacionSubscription =
              _ubicacionStreamController.stream.listen((_) {
            // Actualizar el estado del diálogo cuando cambie la ubicación
            setDialogState(() {});
          });

          return AlertDialog(
            title: const Text('Confirmar Acción'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_image != null || _webImageBytes != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: kIsWeb && _webImageBytes != null
                            ? MemoryImage(_webImageBytes!) as ImageProvider
                            : FileImage(_image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('¿Deseas subir esta foto como Acción de ${[
                  'Descubrimiento',
                  'Alerta',
                  'Ayuda'
                ][_currentPage]}?'),
                if (_hasTournamentLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color:
                              _isTournamentValid ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isTournamentValid
                                ? 'Esta acción será válida para el torneo actual.'
                                : 'Esta acción no es válida para el torneo. Debes acercarte al área designada.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isTournamentValid
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_ubicacionEnProgreso || _currentPosition == null)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _ubicacionEnProgreso
                                ? 'Obteniendo ubicación...'
                                : 'Se requiere ubicación para continuar',
                            style: TextStyle(
                              fontSize: 12,
                              color: _ubicacionEnProgreso
                                  ? Colors.grey[600]
                                  : Colors.red[700],
                              fontWeight: _ubicacionEnProgreso
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _ubicacionSubscription?.cancel();
                  Navigator.of(context).pop();
                  setState(() {
                    _image = null;
                    _webImageBytes = null;
                  });
                },
                child: const Text('Cancelar'),
              ),
              if (_ubicacionEnProgreso)
                // Mientras se obtiene la ubicación, mostrar botón deshabilitado
                TextButton(
                  onPressed: null, // Deshabilitado
                  child: const Text('Esperando ubicación...'),
                )
              else if (_currentPosition == null)
                // Si no hay ubicación y ya no se está obteniendo, informar al usuario
                TextButton(
                  onPressed: () {
                    // Intentar obtener la ubicación nuevamente
                    _obtenerUbicacion();
                  },
                  child: const Text('Obtener ubicación'),
                )
              else
                // Solo mostrar confirmar si hay ubicación
                TextButton(
                  onPressed: () {
                    _ubicacionSubscription?.cancel();
                    _subirAccion();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirmar'),
                ),
            ],
          );
        });
      },
    );
  }

  Future<void> _subirAccion() async {
    if (_image != null || _webImageBytes != null) {
      // Verificar que se tenga la ubicación
      if (_currentPosition == null) {
        notificationService.showError(
          context,
          'Error: No se ha podido obtener la ubicación. Intenta de nuevo.',
        );
        // Intentar obtener la ubicación nuevamente
        _obtenerUbicacion();
        return;
      }

      final accionesProvider =
          Provider.of<AccionesProvider>(context, listen: false);
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
        setState(() {
          _isUploading = true;
        });

        if (kIsWeb && _webImageBytes != null) {
          // Para web, enviamos los bytes directamente
          await accionesProvider.subirAccionWeb(
            userId: userId,
            tipo: ['descubrimiento', 'alerta', 'ayuda'][_currentPage],
            imageBytes: _webImageBytes!,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            isTournamentValid: _isTournamentValid,
          );
        } else if (_image != null) {
          // Para móvil, enviamos el path del archivo
          await accionesProvider.subirAccion(
            userId: userId,
            tipo: ['descubrimiento', 'alerta', 'ayuda'][_currentPage],
            imagePath: _image!.path,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            isTournamentValid: _isTournamentValid,
          );
        }

        notificationService.showSuccess(
          context,
          'Acción subida correctamente',
        );

        setState(() {
          _image = null;
          _webImageBytes = null;
          _isUploading = false;
        });

        Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
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
                onTap: () {
                  if (ios) {
                    _abrirCamara();
                  }
                },
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    HapticFeedback.lightImpact();
                  },
                  itemCount: imagenes.length,
                  itemBuilder: (context, index) {
                    return Transform.scale(
                      scale: index == _currentPage
                          ? scale
                          : 1.0, // Solo aplica el zoom al elemento actual
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            scale: scale,
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
                      bottom: (screenHeight * 0.11) - animationOffset,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _isDraggingVertically
                                ? Offset.zero
                                : Offset(0, _bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: (screenHeight * 0.06) - animationOffset,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _isDraggingVertically
                                ? Offset.zero
                                : Offset(0, _bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
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
                            title: Text(
                              titulosSinSalto[_currentPage],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'YesevaOne',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(descripciones[_currentPage],
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16)),
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
        IgnorePointer(
          ignoring: !_isCompressing && !_isUploading,
          child: AnimatedOpacity(
            opacity: (_isCompressing || _isUploading) ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isUploading ? 'Subiendo...' : 'Procesando imagen...',
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        fontFamily: 'YesevaOne',
                        fontWeight: FontWeight.normal,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _isDraggingVertically = false;
    _lastHapticProgress = 0.0;

    final currentProgress = _dragProgress;

    // Animamos directamente desde el valor actual hasta 0
    _dragAnimationController.value = currentProgress;
    _dragAnimationController
        .animateTo(
      0.0,
      curve: Curves.easeOutCubic,
      duration: Duration(milliseconds: (300 * currentProgress).round()),
    )
        .whenComplete(() {
      setState(() {
        _dragProgress = 0.0;
      });
      // Reanudar la animación de rebote
      if (mounted) {
        _bounceAnimationController.reset();
        _startBounceAnimation();
      }
    });
  }

  @override
  void dispose() {
    _ubicacionSubscription?.cancel();
    _ubicacionStreamController.close();
    _bounceAnimationController.dispose();
    _dragAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Método para cargar datos del torneo desde SharedPreferences
  Future<void> _cargarDatosTorneo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final tournamentLat = prefs.getDouble('torneo_latitud') ?? 0.0;
      final tournamentLong = prefs.getDouble('torneo_longitud') ?? 0.0;
      final radius = prefs.getInt('torneo_metros') ?? 100;

      setState(() {
        _tournamentLatitude = tournamentLat;
        _tournamentLongitude = tournamentLong;
        _tournamentRadius = radius.toDouble();
        _hasTournamentLocation = tournamentLat != 0.0 && tournamentLong != 0.0;
      });

      // Si hay una ubicación de torneo y ya tenemos la ubicación actual, validar
      if (_hasTournamentLocation && _currentPosition != null) {
        _validarProximidadTorneo();
      }
    } catch (e) {
      developer.log('Error al cargar datos de torneo: $e');
    }
  }

  // Método para validar la proximidad al torneo
  void _validarProximidadTorneo() {
    if (!_hasTournamentLocation ||
        _currentPosition == null ||
        _tournamentRadius == null) {
      setState(() {
        _isTournamentValid = false;
      });
      return;
    }

    try {
      // Calcular distancia entre la ubicación actual y la ubicación del torneo
      final distancia = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _tournamentLatitude!,
        _tournamentLongitude!,
      );

      // Verificar si la distancia está dentro del radio permitido
      setState(() {
        _isTournamentValid = distancia <= _tournamentRadius!;
      });

      developer.log(
          'Distancia al torneo: $distancia metros. Radio permitido: $_tournamentRadius. Válido: $_isTournamentValid');
    } catch (e) {
      developer.log('Error al validar proximidad al torneo: $e');
      setState(() {
        _isTournamentValid = false;
      });
    }
  }
}
