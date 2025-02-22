class UserFriend {
  final String id;
  final String friendId;
  final String nombre;
  final String apellido;
  final String? pendingId;
  final String slogan;
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;

  UserFriend({
    required this.id,
    required this.friendId,
    required this.nombre,
    required this.apellido,
    required this.pendingId,
    required this.slogan,
    required this.cabello,
    required this.vestimenta,
    required this.barba,
    required this.detalleFacial,
    required this.detalleAdicional,
  });

  factory UserFriend.fromJson(Map<String, dynamic> json) {
    return UserFriend(
      id: json['id'],
      friendId: json['friend_id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      pendingId: json['pending_id'],
      slogan: json['slogan'],
      cabello: json['cabello'],
      vestimenta: json['vestimenta'],
      barba: json['barba'],
      detalleFacial: json['detalle_facial'],
      detalleAdicional: json['detalle_adicional'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friend_id': friendId,
      'nombre': nombre,
      'apellido': apellido,
      'pending_id': pendingId,
      'slogan': slogan,
      'cabello': cabello,
      'vestimenta': vestimenta,
      'barba': barba,
      'detalle_facial': detalleFacial,
      'detalle_adicional': detalleAdicional,
    };
  }
}

