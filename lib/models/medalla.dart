class Medalla {
  final String id;
  final String nombre;
  final String descripcion;
  final int dificultad;
  final bool requiereAmistades;
  final bool requierePuntos;
  final bool requiereAcciones;
  final bool requiereTorneos;
  final bool requiereVictoriaTorneos;
  final int numeroRequerido;
  final bool desbloqueada;
  final double progreso;

  const Medalla({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.dificultad,
    required this.requiereAmistades,
    required this.requierePuntos,
    required this.requiereAcciones,
    required this.requiereTorneos,
    required this.requiereVictoriaTorneos,
    this.desbloqueada = false,
    this.progreso = 0.0,
    this.numeroRequerido = 0,
  });

  factory Medalla.fromJson(Map<String, dynamic> json) {
    return Medalla(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      dificultad: json['dificultad'],
      requiereAmistades: json['requiere_amistades'],
      requierePuntos: json['requiere_puntos'],
      requiereAcciones: json['requiere_acciones'],
      requiereTorneos: json['requiere_torneos'],
      requiereVictoriaTorneos: json['requiere_victoria_torneos'],
      numeroRequerido: json['numero_requerido'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'nombre': nombre,
      'descripcion': descripcion,
      'dificultad': dificultad,
      'requiere_amistades': requiereAmistades,
      'requiere_puntos': requierePuntos,
      'requiere_acciones': requiereAcciones,
      'requiere_torneos': requiereTorneos,
      'requiere_victoria_torneos': requiereVictoriaTorneos,
      'numero_requerido': numeroRequerido,
    };
  }
}

class MedallaUsuario {
  final String id;
  final String idUsuario;
  final String idMedalla;
  final DateTime fechaGanada;

  const MedallaUsuario({
    required this.id,
    required this.idUsuario,
    required this.idMedalla,
    required this.fechaGanada,
  });

  factory MedallaUsuario.fromJson(Map<String, dynamic> json) {
    return MedallaUsuario(
      id: json['id'],
      idUsuario: json['id_usuario'],
      idMedalla: json['id_medalla'],
      fechaGanada: DateTime.parse(json['fecha_ganada']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_usuario': idUsuario,
      'id_medalla': idMedalla,
      'fecha_ganada': fechaGanada,
    };
  }
}