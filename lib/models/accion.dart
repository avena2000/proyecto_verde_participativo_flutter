import 'package:flutter/material.dart';

class Accion {
  final int id;
  final String titulo;
  final String imagen;
  final String tipo;
  final Color color;

  Accion({
    required this.id,
    required this.titulo,
    required this.imagen,
    required this.tipo,
    required this.color,
  });

  factory Accion.fromJson(Map<String, dynamic> json) {
    return Accion(
      id: json['id'],
      titulo: json['titulo'],
      imagen: json['imagen'],
      tipo: json['tipo'],
      color: Color(int.parse(json['color'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
      'tipo': tipo,
      'color': color.value.toRadixString(16),
    };
  }
}