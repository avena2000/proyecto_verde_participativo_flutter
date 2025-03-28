import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_animated/auto_animated.dart';
import 'package:proyecto_verde_participativo/models/torneo_resumen.dart';
import 'package:proyecto_verde_participativo/models/user_ranking.dart';
import 'package:proyecto_verde_participativo/screens/home_page_friend.dart';
import 'package:proyecto_verde_participativo/widgets/action_user_personaje.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  List<UserRanking> _ranking = [];
  List<TorneoResumen> _torneos = [];
  String _currentUserId = '';
  bool _isLoading = true;
  bool _loadingTorneos = true;

  // "General" es el valor por defecto, representa el ranking global
  String _selectedOption = "General";
  String? _selectedTorneoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullScreenMode();
    _loadRanking();
    _loadTorneos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setFullScreenMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  Future<void> _loadTorneos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        setState(() => _loadingTorneos = false);
        return;
      }

      final response = await _apiService.get(
        '/users/$userId/torneos',
        parser: (data) {
          if (data is List) {
            return data.map((item) => TorneoResumen.fromJson(item)).toList();
          }
          return <TorneoResumen>[];
        },
      );

      setState(() {
        _torneos = response;
        _loadingTorneos = false;
      });
    } catch (e) {
      setState(() => _loadingTorneos = false);
    }
  }

  Future<void> _loadRanking() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId') ?? '';

      final endpoint = _selectedTorneoId != null
          ? '/ranking/torneo/$_selectedTorneoId'
          : '/ranking';

      final response = await _apiService.get(
        endpoint,
        parser: (data) {
          if (data is List) {
            return data.map((item) => UserRanking.fromJson(item)).toList();
          }
          return <UserRanking>[];
        },
      );

      setState(() {
        _ranking = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onOptionSelected(String option, String? torneoId) {
    if (_selectedOption != option || _selectedTorneoId != torneoId) {
      setState(() {
        _selectedOption = option;
        _selectedTorneoId = torneoId;
      });
      _loadRanking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Color(AppColors.darkGreen),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _selectedOption == "General"
                ? 'Ranking Global'
                : 'Torneo: $_selectedOption',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'YesevaOne',
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _ranking.length < 3
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "Todavía no han participado suficientes personas",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : LiveList.options(
                          options: LiveOptions(
                            delay: Duration(milliseconds: 100),
                            showItemInterval: Duration(milliseconds: 150),
                            showItemDuration: Duration(milliseconds: 300),
                            visibleFraction: 0.05,
                            reAnimateOnVisibility: false,
                          ),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top +
                                kToolbarHeight +
                                16,
                            bottom: 16,
                          ),
                          itemCount:
                              _ranking.length + (_ranking.length >= 3 ? 1 : 0),
                          itemBuilder: (context, index, animation) {
                            if (index == 0 && _ranking.length >= 3) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: _buildTop3(),
                                ),
                              );
                            }
                            final rankingIndex =
                                _ranking.length >= 3 ? index - 1 : index;
                            if (rankingIndex < 3) {
                              return const SizedBox.shrink();
                            }
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: _buildRankingItem(
                                    rankingIndex, _ranking[rankingIndex]),
                              ),
                            );
                          },
                        ),
            ),
            // Selector de opciones (General y Torneos)
            _buildOptionSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSelector() {
    return Container(
      height: 70,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Color(AppColors.darkGreen).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _loadingTorneos
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                // Opción General (siempre presente)
                _buildOptionItem("General", null),
                // Opciones de torneos
                ..._torneos.map(
                    (torneo) => _buildOptionItem(torneo.nombre, torneo.id)),
              ],
            ),
    );
  }

  Widget _buildOptionItem(String label, String? torneoId) {
    final isSelected = _selectedOption == label;

    return GestureDetector(
      onTap: () => _onOptionSelected(label, torneoId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(AppColors.primaryGreen)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Color(AppColors.primaryGreenDark)
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTop3() {
    return _Top3Animation(
      ranking: _ranking,
      currentUserId: _currentUserId,
    );
  }

  Widget _buildRankingItem(int index, UserRanking user) {
    final isCurrentUser = user.userId == _currentUserId;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: ActionUserPersonaje(
                      size: 50,
                      cabello: user.cabello,
                      vestimenta: user.vestimenta,
                      barba: user.barba,
                      detalleFacial: user.detalleFacial,
                      detalleAdicional: user.detalleAdicional,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                "\"${user.slogan}\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '${user.puntos} ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.eco_rounded,
                    color: Color(AppColors.primaryGreen),
                    size: 12,
                  ),
                ]),
                Text(
                  '${user.acciones} acciones',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -30,
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
                '${user.nombre} ${user.apellido}',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'YesevaOne',
                ),
              ),
            ),
          ),
        ]));
  }
}

class _Top3Animation extends StatefulWidget {
  final List<UserRanking> ranking;
  final String currentUserId;

  const _Top3Animation({
    required this.ranking,
    required this.currentUserId,
  });

  @override
  State<_Top3Animation> createState() => _Top3AnimationState();
}

class _Top3AnimationState extends State<_Top3Animation> {
  bool showFirst = false;
  bool showSecond = false;
  bool showThird = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) setState(() => showFirst = true);

    await Future.delayed(Duration(milliseconds: 400));
    if (mounted) setState(() => showSecond = true);

    await Future.delayed(Duration(milliseconds: 400));
    if (mounted) setState(() => showThird = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Primer lugar (aparece primero)
          if (widget.ranking.isNotEmpty)
            AnimatedPositioned(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              bottom: showFirst ? 60 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 400),
                opacity: showFirst ? 1.0 : 0.0,
                child: Center(
                  child: _buildTopPosition(0, widget.ranking[0], 1.0),
                ),
              ),
            ),
          // Segundo lugar (aparece segundo)
          if (widget.ranking.length > 1)
            AnimatedPositioned(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              bottom: showSecond ? 30 : -100,
              left: showSecond ? 0 : -100,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: showSecond ? 1.0 : 0.0,
                child: _buildTopPosition(1, widget.ranking[1], 0.8),
              ),
            ),
          // Tercer lugar (aparece tercero)
          if (widget.ranking.length > 2)
            AnimatedPositioned(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              bottom: showThird ? 30 : -100,
              right: showThird ? 0 : -100,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: showThird ? 1.0 : 0.0,
                child: _buildTopPosition(2, widget.ranking[2], 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPosition(int position, UserRanking user, double scale) {
    final isCurrentUser = user.userId == widget.currentUserId;
    return GestureDetector(
      onTap: () {
        if (!isCurrentUser) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => HomePageFriend(amigoId: user.userId),
            ),
          ).then((secuencia) {});
        }
      },
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: _getPositionColor(position),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: ActionUserPersonaje(
                      size: 120,
                      cabello: user.cabello,
                      vestimenta: user.vestimenta,
                      barba: user.barba,
                      detalleFacial: user.detalleFacial,
                      detalleAdicional: user.detalleAdicional,
                    ),
                  ),
                ),
                if (position == 0)
                  Positioned(
                    top: -50,
                    left: 35,
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.yellow,
                      size: 50,
                    ),
                  ),
                if (position == 1)
                  Positioned(
                    top: -50,
                    left: 50,
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                  ),
                if (position == 2)
                  Positioned(
                    top: -50,
                    left: 50,
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                  ),
                if (isCurrentUser)
                  Positioned(
                    bottom: -10,
                    right: 46,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${user.nombre} ${user.apellido}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${user.puntos} ',
                  style: TextStyle(
                    color: _getPositionColor(position),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.eco_rounded,
                  color: Color(AppColors.primaryGreen),
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 0:
        return Colors.yellow;
      case 1:
        return Colors.grey.shade300;
      case 2:
        return Colors.brown.shade300;
      default:
        return Colors.white;
    }
  }
}
