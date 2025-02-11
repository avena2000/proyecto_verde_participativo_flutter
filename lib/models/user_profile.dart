class UserProfile {
  final String id;
  final String userId;
  final String slogan;
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;

  UserProfile({
    required this.id,
    required this.userId,
    required this.slogan,
    required this.cabello,
    required this.vestimenta,
    required this.barba,
    required this.detalleFacial,
    required this.detalleAdicional,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
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
      'user_id': userId,
      'slogan': slogan,
      'cabello': cabello,
      'vestimenta': vestimenta,
      'barba': barba,
      'detalle_facial': detalleFacial,
      'detalle_adicional': detalleAdicional,
    };
  }
}
