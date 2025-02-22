import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _currentUserId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullScreenMode();
    _loadRanking();
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

  Future<void> _loadRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId') ?? '';

      final response = await _apiService.get(
        '/ranking',
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
      print(e);
      setState(() => _isLoading = false);
      // Manejar el error apropiadamente
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Ranking Global',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'YesevaOne',
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                itemCount: _ranking.length + (_ranking.length >= 3 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0 && _ranking.length >= 3) {
                    return _buildTop3();
                  }
                  final rankingIndex = _ranking.length >= 3 ? index - 1 : index;
                  if (rankingIndex < 3) return const SizedBox.shrink();
                  return _buildRankingItem(
                      rankingIndex, _ranking[rankingIndex]);
                },
              ),
      ),
    );
  }

  Widget _buildTop3() {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segundo lugar
          if (_ranking.length > 1)
            Positioned(
              left: 0,
              bottom: 30,
              child: _buildTopPosition(1, _ranking[1], 0.8),
            ),
          // Primer lugar
          if (_ranking.isNotEmpty)
            Positioned(
              bottom: 60,
              child: _buildTopPosition(0, _ranking[0], 1.0),
            ),
          // Tercer lugar
          if (_ranking.length > 2)
            Positioned(
              right: 0,
              bottom: 30,
              child: _buildTopPosition(2, _ranking[2], 0.8),
            ),
        ],
      ),
    );
  }

  Widget _buildTopPosition(int position, UserRanking user, double scale) {
    final isCurrentUser = user.userId == _currentUserId;
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
                        )),
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
                        )),
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
              Row(mainAxisSize: MainAxisSize.min, children: [
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
              ]),
            ],
          ),
        ));
  }

  Widget _buildRankingItem(int index, UserRanking user) {
    final isCurrentUser = user.userId == _currentUserId;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            subtitle: Text(
              textAlign: TextAlign.center,
              user.slogan,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.7),
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
