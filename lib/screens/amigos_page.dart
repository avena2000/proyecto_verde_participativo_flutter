import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_verde_participativo/models/user_friend.dart';
import 'package:proyecto_verde_participativo/screens/home_page.dart';
import 'package:proyecto_verde_participativo/screens/home_page_friend.dart';
import 'package:proyecto_verde_participativo/widgets/action_user_personaje.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/personaje_widget.dart';
import '../widgets/agregar_amigo_bottom_sheet.dart';

class MisAmigos extends StatefulWidget {
  final ScrollController scrollController;

  const MisAmigos({
    super.key,
    required this.scrollController,
  });

  @override
  State<MisAmigos> createState() => _MisAmigosState();
}

class _MisAmigosState extends State<MisAmigos> {
  final ApiService _apiService = ApiService();
  List<UserFriend> _amigos = [];
  bool _isLoading = true;
  String? _userId;

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'YesevaOne',
        ),
      ),
    );
  }

  Future<void> _aceptarSolicitud(String amigoId) async {
    try {
      if (_userId != null) {
        await _apiService.put(
          '/users/$_userId/friends/$amigoId/accept',
        );
        await _cargarAmigos();
        await HomePage.actualizarEstadisticas(context);
      }
    } catch (e) {
      debugPrint('Error al aceptar solicitud: $e');
    }
  }

  Widget _buildFriendCard(
      UserFriend amigo, bool isSolicitudRecibida, bool isSolicitudEnviada) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => HomePageFriend(amigoId: amigo.friendId),
              ),
            ).then((secuencia) {
              HomePage.mantainFullScreenMode(context);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, top: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionUserPersonaje(userId: amigo.friendId, size: 100),
                  if (amigo.slogan.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        '"${amigo.slogan}"',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSolicitudRecibida) ...[
                        IconButton(
                          onPressed: () => _aceptarSolicitud(amigo.friendId),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _eliminarAmigo(amigo.friendId),
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: Colors.red.withOpacity(0.7),
                            size: 28,
                          ),
                        ),
                      ] else if (!isSolicitudEnviada) ...[
                        IconButton(
                          onPressed: () => _eliminarAmigo(amigo.friendId),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                      ] else ...[
                        IconButton(
                          onPressed: () => _eliminarAmigo(amigo.friendId),
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: Colors.red.withOpacity(0.7),
                            size: 28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(AppColors.primaryGreen),
                  Color(AppColors.primaryGreenDark),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${amigo.nombre} ${amigo.apellido}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'YesevaOne',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarAmigos();
  }

  @override
  void dispose() {
    // Actualizar estadísticas cuando se cierre la página de amigos
    HomePage.actualizarEstadisticas(context);
    super.dispose();
  }

  Future<void> _cargarAmigos() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');

      if (_userId != null) {
        final response = await _apiService.get(
          '/users/$_userId/friends',
          parser: (data) =>
              (data as List).map((item) => UserFriend.fromJson(item)).toList(),
        );

        setState(() {
          _amigos = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar amigos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarAmigo(String amigoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        await _apiService.delete('/users/$userId/friends/$amigoId');
        setState(() {
          _amigos.removeWhere((amigo) => amigo.friendId == amigoId);
        });
        await HomePage.actualizarEstadisticas(context);
      }
    } catch (e) {
      debugPrint('Error al eliminar amigo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.62,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Color(AppColors.darkGreen),
          borderRadius: BorderRadius.circular(27),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Mis Amigos',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _amigos.isEmpty
                        ? Center(
                            child: Text(
                              'No tienes amigos ni solicitudes pendientes',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView(
                            controller: widget.scrollController,
                            children: [
                              // Solicitudes Recibidas
                              if (_amigos.any(
                                  (amigo) => amigo.pendingId == _userId)) ...[
                                _buildSectionTitle('Solicitudes Recibidas'),
                                ..._amigos
                                    .where(
                                        (amigo) => amigo.pendingId == _userId)
                                    .map((amigo) =>
                                        _buildFriendCard(amigo, true, false)),
                              ],

                              // Amigos
                              if (_amigos
                                  .any((amigo) => amigo.pendingId == null)) ...[
                                _buildSectionTitle('Amigos'),
                                ..._amigos
                                    .where((amigo) => amigo.pendingId == null)
                                    .map((amigo) =>
                                        _buildFriendCard(amigo, false, false)),
                              ],

                              // Solicitudes Enviadas
                              if (_amigos.any((amigo) =>
                                  amigo.pendingId != null &&
                                  amigo.pendingId != _userId)) ...[
                                _buildSectionTitle('Solicitudes Enviadas'),
                                ..._amigos
                                    .where((amigo) =>
                                        amigo.pendingId != null &&
                                        amigo.pendingId != _userId)
                                    .map((amigo) =>
                                        _buildFriendCard(amigo, false, true)),
                              ],
                            ],
                          ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(AppColors.primaryGreen),
                      Color(AppColors.primaryGreenDark),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(AppColors.primaryGreen).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Color(AppColors.darkGreen),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(27),
                              topRight: Radius.circular(27),
                            ),
                          ),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SingleChildScrollView(
                            child: AgregarAmigoBottomSheet(
                              scrollController: widget.scrollController,
                            ),
                          ),
                        ),
                      ).then((secuencia) async {
                        await HomePage.actualizarEstadisticas(context);
                        _cargarAmigos();
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Agregar Amigos',
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ));
  }
}
