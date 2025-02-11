import 'package:flutter/material.dart';

enum NotificationType { success, error, info, warning }

class CustomNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onDismiss;
  final Duration duration;

  const CustomNotification({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.onDismiss,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    // Iniciar el temporizador para auto-dismiss
    Future.delayed(widget.duration - const Duration(milliseconds: 500), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green.shade800;
      case NotificationType.error:
        return Colors.red.shade800;
      case NotificationType.warning:
        return Colors.orange.shade800;
      case NotificationType.info:
        return Colors.blue.shade800;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                  Row(
                    children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Icon(
                                  _icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Text(
                                textAlign: TextAlign.center,
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,

                                fontSize: 16,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                          ),
                        ),
                    ],
                  ),
                  
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
