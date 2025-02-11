class UserBasicInfo {
  final String id;
  final String userId;
  final String nombre;
  final String apellido;
  final String telefono;


  UserBasicInfo({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.apellido,
    required this.telefono,
  });



  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      telefono: json['numero'],

    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
    };

  }
}