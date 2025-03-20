class TorneoResumen {
  final String id;
  final String nombre;

  TorneoResumen({
    required this.id,
    required this.nombre,
  });

  factory TorneoResumen.fromJson(Map<String, dynamic> json) {
    return TorneoResumen(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
    );
  }
}
