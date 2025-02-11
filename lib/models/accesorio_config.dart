
class AccesorioConfig {
  final String nombre;
  final String puntos;
  final double bottomOffset;
  final double leftOffset;
  final double rightOffset;
  final double heightFactor;

  const AccesorioConfig({
    required this.nombre,
    this.puntos = '0',
    this.bottomOffset = 0.47,
    this.leftOffset = 0,
    this.rightOffset = 4,
    this.heightFactor = 0.55,
  });


  static Map<String, AccesorioConfig> cabelloConfigs = {
    'default': AccesorioConfig(nombre: 'default', bottomOffset: 0.72, leftOffset: 0, rightOffset: 15, heightFactor: 0.29),
    '1': AccesorioConfig(nombre: '1', puntos: '0',bottomOffset: 0.65, leftOffset: 0, rightOffset: 4, heightFactor: 0.35),
    '2': AccesorioConfig(nombre: '2', puntos: '0', bottomOffset: 0.74, leftOffset: 0, rightOffset: 4, heightFactor: 0.32),
    '3': AccesorioConfig(nombre: '3', puntos: '0', bottomOffset: 0.67, leftOffset: 11, rightOffset: 4, heightFactor: 0.4),
    '4': AccesorioConfig(nombre: '4', puntos: '100', bottomOffset: 0.74, leftOffset: 3, rightOffset: 4, heightFactor: 0.24),
    '5': AccesorioConfig(nombre: '5', puntos: '100', bottomOffset: 0.72, leftOffset: 0, rightOffset: 4, heightFactor: 0.30),
    '6': AccesorioConfig(nombre: '6', puntos: '100', bottomOffset: 0.71, leftOffset: 0, rightOffset: 4, heightFactor: 0.30),
    '7': AccesorioConfig(nombre: '7', puntos: '200', bottomOffset: 0.58, leftOffset: 0, rightOffset: 4, heightFactor: 0.42),
    '8': AccesorioConfig(nombre: '8', puntos: '200', bottomOffset: 0.67, leftOffset: 0, rightOffset: 4, heightFactor: 0.33),
    '9': AccesorioConfig(nombre: '9', puntos: '400', bottomOffset: 0.78, leftOffset: 0, rightOffset: 4, heightFactor: 0.25),
    '10': AccesorioConfig(nombre: '10', puntos: '400', bottomOffset: 0.72, leftOffset: 0, rightOffset: 4, heightFactor: 0.30),
  };

  static Map<String, AccesorioConfig> vestimentaConfigs = {
    'default': AccesorioConfig(nombre: 'default', bottomOffset: 0.58, leftOffset: 155, rightOffset: 4, heightFactor: 0.08),
    '1': AccesorioConfig(nombre: '1', puntos: '0', bottomOffset: 0.51, leftOffset: 0, rightOffset: 10, heightFactor: 0.25),
    '2': AccesorioConfig(nombre: '2', puntos: '0', bottomOffset: 0.56, leftOffset: 0, rightOffset: 5, heightFactor: 0.19),
    '3': AccesorioConfig(nombre: '3', puntos: '200', bottomOffset: 0.56, leftOffset: 0, rightOffset: 4, heightFactor: 0.165),
    '4': AccesorioConfig(nombre: '4', puntos: '400', bottomOffset: 0.58, leftOffset: 155, rightOffset: 4, heightFactor: 0.08),
    '5': AccesorioConfig(nombre: '5', puntos: '600', bottomOffset: 0.575, leftOffset: 155, rightOffset: 4, heightFactor: 0.09),

  };

  static Map<String, AccesorioConfig> barbaConfigs = {
    '1': AccesorioConfig(nombre: '1', puntos: '0', bottomOffset: 0.62, leftOffset: 0, rightOffset: 4, heightFactor: 0.24),
    '2': AccesorioConfig(nombre: '2', puntos: '0', bottomOffset: 0.63, leftOffset: 0, rightOffset: 6, heightFactor: 0.18),
    '3': AccesorioConfig(nombre: '3', puntos: '100',bottomOffset: 0.61, leftOffset: 0, rightOffset: 4, heightFactor: 0.20),
    '4': AccesorioConfig(nombre: '4', puntos: '200', bottomOffset: 0.65, leftOffset: 0, rightOffset: 4, heightFactor: 0.20),
    '5': AccesorioConfig(nombre: '5', puntos: '400', bottomOffset: 0.65, leftOffset: 0, rightOffset: 4, heightFactor: 0.187),
    '6': AccesorioConfig(nombre: '6', puntos: '600', bottomOffset: 0.60, leftOffset: 0, rightOffset: 4, heightFactor: 0.15),
  };


  static Map<String, AccesorioConfig> detalleFacialConfigs = {
    '1': AccesorioConfig(nombre: '1', puntos: '300', bottomOffset: 0.76, leftOffset: 80, rightOffset: 4, heightFactor: 0.03),
    '2': AccesorioConfig(nombre: '2', puntos: '300', bottomOffset: 0.72, leftOffset: 0, rightOffset: 4, heightFactor: 0.15),
  };

  static Map<String, AccesorioConfig> detalleAdicionalConfigs = {
    '1': AccesorioConfig(nombre: '1', puntos: '300', bottomOffset: 0.82, leftOffset: 0, rightOffset: 72, heightFactor: 0.06),
    '2': AccesorioConfig(nombre: '2', puntos: '300', bottomOffset: 0.24, leftOffset: 0, rightOffset: 4, heightFactor: 0.5),
  };
}