class UserRanking {
  final String userId;
  final int puntos;
  final int acciones;
  final int torneosGanados;
  final int cantidadAmigos;
  final String slogan;
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;
  final String nombre;
  final String apellido;

  UserRanking({
    required this.userId,
    required this.puntos,
    required this.acciones,
    required this.torneosGanados,
    required this.cantidadAmigos,
    required this.slogan,
    required this.cabello,
    required this.vestimenta,
    required this.barba,
    required this.detalleFacial,
    required this.detalleAdicional,
    required this.nombre,
    required this.apellido,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      userId: json['user_id'] as String,
      puntos: json['puntos'] as int,
      acciones: json['acciones'] as int,
      torneosGanados: json['torneos_ganados'] as int,
      cantidadAmigos: json['cantidad_amigos'] as int,
      slogan: json['slogan'] as String,
      cabello: json['cabello'] as String,
      vestimenta: json['vestimenta'] as String,
      barba: json['barba'] as String,
      detalleFacial: json['detalle_facial'] as String,
      detalleAdicional: json['detalle_adicional'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'puntos': puntos,
      'acciones': acciones,
      'torneos_ganados': torneosGanados,
      'cantidad_amigos': cantidadAmigos,
      'slogan': slogan,
      'cabello': cabello,
      'vestimenta': vestimenta,
      'barba': barba,
      'detalle_facial': detalleFacial,
      'detalle_adicional': detalleAdicional,
      'nombre': nombre,
      'apellido': apellido,
    };
  }
}
