import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserAction {
  final String id;
  final String userId;
  final String tipoAccion;
  final String foto;
  final double latitud;
  final double longitud;
  final String ciudad;
  final String lugar;
  final bool enColaboracion;
  final List<String>? colaboradores;
  final bool esParaTorneo;
  final String? idTorneo;
  final DateTime createdAt;
  final DateTime? deletedAt;

  UserAction({
    required this.id,
    required this.userId,
    required this.tipoAccion,
    required this.foto,
    required this.latitud,
    required this.longitud,
    required this.ciudad,
    required this.lugar,
    required this.enColaboracion,
    this.colaboradores,
    required this.esParaTorneo,
    this.idTorneo,
    required this.createdAt,
    this.deletedAt,
  });

  factory UserAction.fromJson(Map<String, dynamic> json) {
    String fotoUrl = json['foto'];

    if (fotoUrl.contains("localhost")) {
      final baseUrl = dotenv.env['CDN_URL']!;
      fotoUrl = fotoUrl.replaceAll("localhost:8080", baseUrl);
    }

    return UserAction(
      id: json['id'],
      userId: json['user_id'],
      tipoAccion: json['tipo_accion'],
      foto: fotoUrl,
      latitud: json['latitud'],
      longitud: json['longitud'],
      ciudad: json['ciudad'],
      lugar: json['lugar'],
      enColaboracion: json['en_colaboracion'],
      colaboradores: json['colaboradores'] != null
          ? List<String>.from(json['colaboradores'])
          : null,
      esParaTorneo: json['es_para_torneo'],
      idTorneo: json['id_torneo'],
      createdAt: DateTime.parse(json['created_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }
}
