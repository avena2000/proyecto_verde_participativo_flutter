import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:proyecto_verde_participativo/constants/colors.dart';
import '../models/user_action.dart';

class FullscreenImageGallery extends StatefulWidget {
  final List<UserAction> acciones;
  final int initialIndex;

  const FullscreenImageGallery({
    super.key,
    required this.acciones,
    required this.initialIndex,
  });

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  late AnimationController _dragAnimationController;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  int _dragDirection = 0; // -1 para arriba, 1 para abajo, 0 para ninguno

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
      _dragDirection = _dragOffset.sign.toInt();
      double progress = (_dragOffset.abs() / 400.0).clamp(0.0, 1.0);
      _animationController.value = progress;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset.abs() > 250 || velocity.abs() > 500) {
      _animateOut();
    } else {
      _animateBack();
    }
  }

  void _animateOut() {
    _animationController
        .animateTo(1.0, duration: const Duration(milliseconds: 200))
        .then((_) {
      Navigator.of(context).pop();
    });
  }

  void _animateBack() {
    setState(() {
      _isDragging = false;
    });

    _animationController.animateTo(0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart);

    final double startOffset = _dragOffset;
    _dragAnimationController.value = 1.0;

    void updateOffset() {
      if (mounted) {
        setState(() {
          _dragOffset = startOffset * _dragAnimationController.value;
        });
      }
    }

    _dragAnimationController.addListener(updateOffset);
    _dragAnimationController
        .animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    )
        .whenComplete(() {
      _dragAnimationController.removeListener(updateOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _animateOut();
        return false;
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = _animationController.value;

          return Material(
            type: MaterialType.transparency,
            child: Container(
              color: Colors.black.withOpacity(1 - progress),
              child: GestureDetector(
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: Transform.scale(
                        scale: 1.0 - (progress * 0.2),
                        child: PhotoViewGallery.builder(
                          pageController: _pageController,
                          itemCount: widget.acciones.length,
                          builder: (context, index) {
                            return PhotoViewGalleryPageOptions(
                              imageProvider: CachedNetworkImageProvider(
                                  widget.acciones[index].foto),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                              heroAttributes:
                                  PhotoViewHeroAttributes(tag: 'image_$index'),
                            );
                          },
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          loadingBuilder: (context, event) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          backgroundDecoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // Información de ubicación
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(children: [
                              Row(
                                children: [
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      ('Acción de ${widget.acciones[_currentIndex].tipoAccion}').toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'yesevaone',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                   Icon(Icons.location_on,
                                      color: Color(AppColors.primaryGreen),
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.acciones[_currentIndex].lugar,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ])),
                      ),
                    ),
                    // Botón de cerrar
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _animateOut,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _dragAnimationController.dispose();
    super.dispose();
  }
}
