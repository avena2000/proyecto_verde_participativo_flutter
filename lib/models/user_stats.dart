class UserStats {
  final String id;
  final String userId;
  final int puntos;
  final int acciones;
  final int torneosParticipados;
  final int torneosGanados;
  final int cantidadAmigos;
  final bool esDuenoTorneo;
  final int pendingMedalla;
  final int pendingAmigos;
  final String? torneoId;

  UserStats({
    required this.id,
    required this.userId,
    required this.puntos,
    required this.acciones,
    required this.torneosParticipados,
    required this.torneosGanados,
    required this.cantidadAmigos,
    required this.esDuenoTorneo,
    required this.pendingMedalla,
    required this.pendingAmigos,
    required this.torneoId,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'],
      userId: json['user_id'],
      puntos: json['puntos'],
      acciones: json['acciones'],
      torneosParticipados: json['torneos_participados'],
      torneosGanados: json['torneos_ganados'],
      cantidadAmigos: json['cantidad_amigos'],
      esDuenoTorneo: json['es_dueno_torneo'],
      pendingMedalla: json['pending_medalla'],
      pendingAmigos: json['pending_amigo'],
      torneoId: json['torneo_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'puntos': puntos,
      'acciones': acciones,
      'torneos_participados': torneosParticipados,
      'torneos_ganados': torneosGanados,
      'cantidad_amigos': cantidadAmigos,
      'es_dueno_torneo': esDuenoTorneo,
      'torneo_id': torneoId,
    };
  }
}
