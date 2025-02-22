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
    'default': AccesorioConfig(
        nombre: 'default',
        bottomOffset: 0.72,
        leftOffset: 0,
        rightOffset: 15,
        heightFactor: 0.29),
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.65,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.35),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.74,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.32),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '0',
        bottomOffset: 0.67,
        leftOffset: 11,
        rightOffset: 4,
        heightFactor: 0.4),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '100',
        bottomOffset: 0.74,
        leftOffset: 3,
        rightOffset: 4,
        heightFactor: 0.24),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '100',
        bottomOffset: 0.72,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.30),
    '6': AccesorioConfig(
        nombre: '6',
        puntos: '100',
        bottomOffset: 0.71,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.30),
    '7': AccesorioConfig(
        nombre: '7',
        puntos: '200',
        bottomOffset: 0.58,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.42),
    '8': AccesorioConfig(
        nombre: '8',
        puntos: '200',
        bottomOffset: 0.67,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.33),
    '9': AccesorioConfig(
        nombre: '9',
        puntos: '400',
        bottomOffset: 0.78,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.25),
    '10': AccesorioConfig(
        nombre: '10',
        puntos: '400',
        bottomOffset: 0.72,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.30),
  };

  static Map<String, AccesorioConfig> vestimentaConfigs = {
    'default': AccesorioConfig(
        nombre: 'default',
        bottomOffset: 0.58,
        leftOffset: 155,
        rightOffset: 4,
        heightFactor: 0.08),
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.51,
        leftOffset: 0,
        rightOffset: 10,
        heightFactor: 0.25),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.56,
        leftOffset: 0,
        rightOffset: 5,
        heightFactor: 0.19),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '200',
        bottomOffset: 0.56,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.165),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '400',
        bottomOffset: 0.58,
        leftOffset: 155,
        rightOffset: 4,
        heightFactor: 0.08),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '600',
        bottomOffset: 0.575,
        leftOffset: 155,
        rightOffset: 4,
        heightFactor: 0.09),
  };

  static Map<String, AccesorioConfig> barbaConfigs = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.62,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.24),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.63,
        leftOffset: 0,
        rightOffset: 6,
        heightFactor: 0.18),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '100',
        bottomOffset: 0.61,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.20),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '200',
        bottomOffset: 0.65,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.20),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '400',
        bottomOffset: 0.65,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.187),
    '6': AccesorioConfig(
        nombre: '6',
        puntos: '600',
        bottomOffset: 0.60,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.15),
  };

  static Map<String, AccesorioConfig> detalleFacialConfigs = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '300',
        bottomOffset: 0.76,
        leftOffset: 80,
        rightOffset: 4,
        heightFactor: 0.03),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '300',
        bottomOffset: 0.72,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.15),
  };

  static Map<String, AccesorioConfig> detalleAdicionalConfigs = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '300',
        bottomOffset: 0.82,
        leftOffset: 0,
        rightOffset: 72,
        heightFactor: 0.06),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '300',
        bottomOffset: 0.24,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.5),
  };

  static Map<String, AccesorioConfig> cabelloConfigsNormalizados = {
    'default': AccesorioConfig(
        nombre: 'default',
        bottomOffset: 0.45,
        leftOffset: 0,
        rightOffset: 8,
        heightFactor: 0.53),
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.34,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.639625),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.49,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.5848),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '0',
        bottomOffset: 0.375,
        leftOffset: 11,
        rightOffset: 4,
        heightFactor: 0.70),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '100',
        bottomOffset: 0.49,
        leftOffset: 2,
        rightOffset: 0,
        heightFactor: 0.4386),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '100',
        bottomOffset: 0.45,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.54825),
    '6': AccesorioConfig(
        nombre: '6',
        puntos: '100',
        bottomOffset: 0.44,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.54825),
    '7': AccesorioConfig(
        nombre: '7',
        puntos: '200',
        bottomOffset: 0.195,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.76755),
    '8': AccesorioConfig(
        nombre: '8',
        puntos: '200',
        bottomOffset: 0.36,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.603075),
    '9': AccesorioConfig(
        nombre: '9',
        puntos: '400',
        bottomOffset: 0.565,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.456875),
    '10': AccesorioConfig(
        nombre: '10',
        puntos: '400',
        bottomOffset: 0.45,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.54825),
  };

  static Map<String, AccesorioConfig> vestimentaConfigsNormalizados = {
    'default': AccesorioConfig(
        nombre: 'default',
        bottomOffset: 0.15,
        leftOffset: 125,
        rightOffset: 4,
        heightFactor: 0.1462),
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.09,
        leftOffset: 0,
        rightOffset: 10,
        heightFactor: 0.43),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.16,
        leftOffset: 0,
        rightOffset: 1,
        heightFactor: 0.35),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '200',
        bottomOffset: 0.16,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.3015375),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '400',
        bottomOffset: 0.14,
        leftOffset: 110,
        rightOffset: 4,
        heightFactor: 0.20),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '600',
        bottomOffset: 0.08,
        leftOffset: 110,
        rightOffset: 4,
        heightFactor: 0.25),
  };

  static Map<String, AccesorioConfig> barbaConfigsNormalizados = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '0',
        bottomOffset: 0.27,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.4386),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '0',
        bottomOffset: 0.29,
        leftOffset: 0,
        rightOffset: 1,
        heightFactor: 0.32895),
    '3': AccesorioConfig(
        nombre: '3',
        puntos: '100',
        bottomOffset: 0.25,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.3655),
    '4': AccesorioConfig(
        nombre: '4',
        puntos: '200',
        bottomOffset: 0.324,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.3655),
    '5': AccesorioConfig(
        nombre: '5',
        puntos: '400',
        bottomOffset: 0.324,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.345),
    '6': AccesorioConfig(
        nombre: '6',
        puntos: '600',
        bottomOffset: 0.60,
        leftOffset: 0,
        rightOffset: 0,
        heightFactor: 0.15),
  };

  static Map<String, AccesorioConfig> detalleFacialConfigsNormalizados = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '300',
        bottomOffset: 0.76,
        leftOffset: 80,
        rightOffset: 4,
        heightFactor: 0.03),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '300',
        bottomOffset: 0.72,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.15),
  };

  static Map<String, AccesorioConfig> detalleAdicionalConfigsNormalizados = {
    '1': AccesorioConfig(
        nombre: '1',
        puntos: '300',
        bottomOffset: 0.82,
        leftOffset: 0,
        rightOffset: 72,
        heightFactor: 0.06),
    '2': AccesorioConfig(
        nombre: '2',
        puntos: '300',
        bottomOffset: 0.24,
        leftOffset: 0,
        rightOffset: 4,
        heightFactor: 0.5),
  };
}
