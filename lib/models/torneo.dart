class Torneo {
  final String id;
  final String idCreator;
  final String nombre;
  final String modalidad;
  final double ubicacionALatitud;
  final double ubicacionALongitud;
  final String nombreUbicacionA;
  final double? ubicacionBLatitud;
  final double? ubicacionBLongitud;
  final String? nombreUbicacionB;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool ubicacionAproximada;
  final int? metrosAprox;
  final bool finalizado;
  final String codeId;
  final bool? ganadorVersus;
  final String? ganadorIndividual;

  Torneo({
    required this.id,
    required this.idCreator,
    required this.nombre,
    required this.modalidad,
    required this.ubicacionALatitud,
    required this.ubicacionALongitud,
    required this.nombreUbicacionA,
    this.ubicacionBLatitud,
    this.ubicacionBLongitud,
    this.nombreUbicacionB,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ubicacionAproximada,
    this.metrosAprox,
    required this.finalizado,
    required this.codeId,
    this.ganadorVersus,
    this.ganadorIndividual,
  });

  factory Torneo.fromJson(Map<String, dynamic> json) {
    return Torneo(
      id: json['id'] as String,
      idCreator: json['id_creator'] as String,
      nombre: json['nombre'] as String,
      modalidad: json['modalidad'] as String,
      ubicacionALatitud: json['ubicacion_a_latitud'] as double,
      ubicacionALongitud: json['ubicacion_a_longitud'] as double,
      nombreUbicacionA: json['nombre_ubicacion_a'] as String,
      ubicacionBLatitud: json['ubicacion_b_latitud'] as double?,
      ubicacionBLongitud: json['ubicacion_b_longitud'] as double?,
      nombreUbicacionB: json['nombre_ubicacion_b'] as String?,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      ubicacionAproximada: json['ubicacion_aproximada'] as bool,
      metrosAprox: json['metros_aproximados'] as int?,
      finalizado: json['finalizado'] as bool,
      codeId: json['code_id'] as String,
      ganadorVersus: json['ganador_versus'] as bool?,
      ganadorIndividual: json['ganador_individual'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'id_creator': idCreator,
      'nombre': nombre,
      'modalidad': modalidad,
      'ubicacion_a_latitud': ubicacionALatitud,
      'ubicacion_a_longitud': ubicacionALongitud,
      'nombre_ubicacion_a': nombreUbicacionA,
      'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
      'fecha_fin': fechaFin.toUtc().toIso8601String(),
      'ubicacion_aproximada': ubicacionAproximada,
      'finalizado': finalizado,
      'code_id': codeId,
    };

    // Agregar campos opcionales solo si tienen valor
    if (ubicacionBLatitud != null) {
      data['ubicacion_b_latitud'] = ubicacionBLatitud;
    }

    if (ubicacionBLongitud != null) {
      data['ubicacion_b_longitud'] = ubicacionBLongitud;
    }

    if (nombreUbicacionB != null) {
      data['nombre_ubicacion_b'] = nombreUbicacionB;
    }

    if (metrosAprox != null) {
      data['metros_aproximados'] = metrosAprox;
    }

    if (ganadorVersus != null) {
      data['ganador_versus'] = ganadorVersus;
    }

    if (ganadorIndividual != null) {
      data['ganador_individual'] = ganadorIndividual;
    }

    return data;
  }
}
