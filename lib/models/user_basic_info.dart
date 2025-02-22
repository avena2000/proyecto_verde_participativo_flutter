class UserBasicInfo {
  final String id;
  final String userId;
  final String nombre;
  final String apellido;
  final String telefono;
  final String friendId;


  UserBasicInfo({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.friendId,
  });



  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      telefono: json['numero'],
      friendId: json['friend_id'],
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