# Documentación Técnica - Proyecto ViVe (Verde Participativo)

## Índice
1. [Introducción](#introducción)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Tecnologías Utilizadas](#tecnologías-utilizadas)
4. [Pantallas y Componentes](#pantallas-y-componentes)
   - [Pantalla de Bienvenida (WelcomePage)](#pantalla-de-bienvenida)
   - [Pantalla de Información Personal (PersonalInfoPage)](#pantalla-de-información-personal)
   - [Pantalla Principal (HomePage)](#pantalla-principal)
   - [Pantalla de Medallas (MisMedallas)](#pantalla-de-medallas)
5. [Componentes Principales](#componentes-principales)
   - [Personaje Virtual](#personaje-virtual)
   - [Sistema de Amigos](#sistema-de-amigos)
   - [Sistema de Torneos](#sistema-de-torneos)
   - [Configuración de Usuario](#configuración-de-usuario)
6. [Modelos de Datos](#modelos-de-datos)
7. [Servicios](#servicios)
8. [Autenticación y Seguridad](#autenticación-y-seguridad)
9. [Flujos de Navegación](#flujos-de-navegación)

## Introducción

ViVe (Verde Participativo) es una aplicación móvil desarrollada en Flutter que promueve acciones ecológicas y sostenibles. La aplicación permite a los usuarios registrar acciones ambientales, participar en torneos, personalizar un avatar virtual, ganar medallas por logros y conectarse con amigos para realizar actividades colaborativas.

La aplicación está diseñada con un enfoque gamificado para incentivar la participación ciudadana en iniciativas medioambientales, convirtiendo acciones ecológicas en una experiencia social y divertida.

## Estructura del Proyecto

El proyecto sigue una estructura organizada por funcionalidades:

```
proyecto_verde_participativo/
├── lib/
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── api_codes.dart
│   │   ├── models/
│   │   │   ├── user_action.dart
│   │   │   ├── user_access.dart
│   │   │   ├── user_basic_info.dart
│   │   │   ├── user_profile.dart
│   │   │   ├── user_stats.dart
│   │   │   ├── api_response.dart
│   │   │   ├── acciones_provider.dart
│   │   │   ├── personaje_provider.dart
│   │   │   ├── medallas_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── welcome_page.dart
│   │   │   │   ├── personal_info_page.dart
│   │   │   │   ├── home_page.dart
│   │   │   │   ├── medallas_page.dart
│   │   │   ├── services/
│   │   │   │   ├── api_service.dart
│   │   │   │   ├── notification_service.dart
│   │   │   │   ├── location_service.dart
│   │   │   ├── utils/
│   │   │   │   ├── functions.dart
│   │   │   │   ├── page_transitions.dart
│   │   │   ├── widgets/
│   │   │   │   ├── login_bottom_sheet.dart
│   │   │   │   ├── registro_bottom_sheet.dart
│   │   │   │   ├── configuracion_bottom_sheet.dart
│   │   │   │   ├── agregar_amigo_bottom_sheet.dart
│   │   │   │   ├── agregar_torneo_bottom_sheet.dart
│   │   │   │   ├── crear_torneo_bottom_sheet.dart
│   │   │   │   ├── personaje_widget.dart
│   │   │   │   ├── action_user_personaje.dart
│   │   │   ├── main.dart
│   ├── assets/
│   │   ├── config/
│   │   │   ├── .env
│   ├── android/
│   │   │   ├── app/
│   │   │   │   ├── src/
│   │   │   │   │   ├── main/
│   │   │   │   │   │   ├── AndroidManifest.xml
```

## Tecnologías Utilizadas

- **Framework**: Flutter
- **Lenguaje**: Dart
- **Gestión de Estado**: Provider
- **Peticiones HTTP**: Dio
- **Almacenamiento Local**: SharedPreferences
- **Animaciones**: auto_animated
- **Geolocalización**: latlong2
- **Variables de Entorno**: flutter_dotenv
- **Seguridad**: crypto (para hash de contraseñas)

## Pantallas y Componentes

### Pantalla de Bienvenida

**Archivo**: `lib/screens/welcome_page.dart`

La pantalla de bienvenida es el punto de entrada para usuarios no autenticados. Presenta la aplicación y proporciona opciones para iniciar sesión o registrarse.

**Componentes principales:**
- Fondo temático ambiental
- Botones de inicio de sesión y registro
- Animaciones de entrada

**Funcionalidades:**
- Navegación a formularios de registro e inicio de sesión mediante bottom sheets
- Verificación de sesión previa

### Pantalla de Información Personal

**Archivo**: `lib/screens/personal_info_page.dart`

Esta pantalla se muestra a los usuarios que se han registrado pero aún no han completado su información personal.

**Componentes principales:**
- Formulario de información personal
- Campos para nombre, apellido y teléfono
- Visualización del correo electrónico (no editable)

**Funcionalidades:**
- Validación de formularios
- Almacenamiento de información personal en el backend y localmente
- Redirección a la pantalla principal una vez completado

```dart
Future<void> _guardarInformacionPersonal() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final _ = await _apiService.put(
      '/users/$userId/basic-info',
      data: {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'numero': _telefonoController.text,
      },
      showMessages: true,
    );

    await prefs.setBool('isPersonalInformation', true);
    await prefs.setString('nombre', _nombreController.text);
    await prefs.setString('apellido', _apellidoController.text);
    await prefs.setString('telefono', _telefonoController.text);

    // Navegación a la pantalla principal
    Navigator.pushAndRemoveUntil(
      context,
      CustomPageTransition(page: HomePage(key: HomePage.homeKey)),
      (route) => false,
    );
  } catch (_) {
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Pantalla Principal

**Archivo**: `lib/screens/home_page.dart`

La pantalla principal (HomePage) es el centro de la aplicación donde los usuarios pueden acceder a todas las funcionalidades principales.

**Componentes principales:**
- Menú Principal con opciones de navegación
- Visualización del personaje virtual personalizable
- Estadísticas del usuario (puntos, acciones, torneos)
- Acceso a medallas y logros
- Sistema de notificaciones para medallas pendientes y solicitudes de amistad

**Funcionalidades:**
- Navegación a diferentes secciones de la aplicación
- Visualización y actualización de estadísticas en tiempo real
- Acceso a la configuración del usuario
- Gestión de acciones ambientales
- Participación en torneos

```dart
class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({
    super.key,
    required this.pendingCount,
  });

  final int pendingCount;
  @override
  Widget build(BuildContext context) {
    final homePageState = context.findAncestorStateOfType<_HomePageState>();
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 21),
            Center(
              child: Text(
                'Menú Principal',
                style: TextStyle(
                  fontFamily: 'YesevaOne',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.military_tech,
              title: 'Mis Medallas',
              subtitle: 'Revisa tus logros',
              pendingCount: pendingCount,
              onTap: () async {
                HapticFeedback.lightImpact();
                // Navegación a la pantalla de medallas
              }
            ),
            // Otros botones del menú...
          ]
        )
    );
  }
}
```

### Pantalla de Medallas

**Archivo**: `lib/screens/medallas_page.dart`

Esta pantalla muestra las medallas y logros que el usuario ha desbloqueado o puede desbloquear mediante acciones ambientales.

**Componentes principales:**
- Grid animado de medallas
- Indicadores de progreso para cada medalla
- Información detallada de cada logro

**Funcionalidades:**
- Visualización de medallas desbloqueadas y bloqueadas
- Progreso actual para cada medalla
- Animaciones de entrada para cada elemento
- Reseteo de notificaciones de medallas pendientes

```dart
class _MedallasContent extends StatelessWidget {
  final ScrollController scrollController;

  const _MedallasContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Mis Medallas',
              style: TextStyle(
                fontFamily: 'YesevaOne',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<MedallasProvider>(
            builder: (context, provider, child) {
              // Implementación del grid de medallas con animaciones
              return Expanded(
                child: LiveGrid.options(
                  // Configuración del grid animado
                )
              );
            }
          )
        ]
      )
    );
  }
}
```

## Componentes Principales

### Personaje Virtual

El sistema de personaje virtual permite a los usuarios personalizar un avatar que los representa en la aplicación.

**Archivos principales:**
- `lib/providers/personaje_provider.dart`
- `lib/widgets/personaje_widget.dart`
- `lib/widgets/action_user_personaje.dart`

**Características personalizables:**
- Cabello
- Vestimenta
- Barba
- Detalle facial
- Detalle adicional

**Funcionalidades:**
- Personalización completa del avatar
- Sincronización con el backend
- Almacenamiento local de preferencias
- Visualización en acciones y perfil

```dart
class PersonajeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String _cabello = 'default';
  String _vestimenta = 'default';
  String _barba = '0';
  String _detalleFacial = '0';
  String _detalleAdicional = '0';

  // Getters y métodos para actualizar el personaje
  
  Future<void> actualizarAccesorios({
    required String cabello,
    required String vestimenta,
    required String barba,
    required String detalleFacial,
    required String detalleAdicional,
    bool showMessages = false,
  }) async {
    _cabello = cabello;
    _vestimenta = vestimenta;
    _barba = barba;
    _detalleFacial = detalleFacial;
    _detalleAdicional = detalleAdicional;

    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cabello', cabello);
    await prefs.setString('vestimenta', vestimenta);
    await prefs.setString('barba', barba);
    await prefs.setString('detalleFacial', detalleFacial);
    await prefs.setString('detalleAdicional', detalleAdicional);

    notifyListeners();
  }
}
```

### Sistema de Amigos

La aplicación incluye un sistema de amigos que permite a los usuarios conectarse entre sí para realizar acciones colaborativas.

**Archivos principales:**
- `lib/widgets/agregar_amigo_bottom_sheet.dart`

**Características:**
- Código único de amistad basado en secuencias de gestos (arriba, abajo, izquierda, derecha)
- Interfaz gestual para agregar amigos
- Notificaciones de solicitudes pendientes

**Funcionalidades:**
- Envío de solicitudes de amistad mediante códigos de gestos
- Visualización del código personal
- Gestión de solicitudes pendientes
- Acciones colaborativas con amigos

```dart
Future<void> agregarAmigo() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  String secuenciaString = _secuencia.map((direccion) {
    switch (direccion) {
      case DireccionGesto.arriba:
        return 'up';
      case DireccionGesto.abajo:
        return 'down';
      case DireccionGesto.izquierda:
        return 'left';
      case DireccionGesto.derecha:
        return 'right';
    }
  }).join('-');

  if (userId != null) {
    try {
      ApiService apiService = ApiService();
      apiService.setContext(context);
      await apiService.post('/users/$userId/friends/add',
          data: {
            'friend_id_request': secuenciaString,
          },
          showMessages: true,
          parser: (data) => data);
      notificationService.showSuccess(
          context, "Solicitud enviada correctamente");
      Navigator.pop(context, _secuencia);
    } catch (_) {}
  }
}
```

### Sistema de Torneos

La aplicación incluye un sistema de torneos que permite a los usuarios competir en desafíos ambientales.

**Archivos principales:**
- `lib/widgets/agregar_torneo_bottom_sheet.dart`
- `lib/widgets/crear_torneo_bottom_sheet.dart`

**Características:**
- Creación de torneos personalizados
- Unión a torneos existentes mediante códigos
- Seguimiento de participación y victorias

**Funcionalidades:**
- Creación de torneos con reglas personalizadas
- Unión a torneos mediante códigos de gestos
- Competición con otros usuarios
- Recompensas por participación y victoria

### Configuración de Usuario

**Archivo**: `lib/widgets/configuracion_bottom_sheet.dart`

Permite a los usuarios gestionar su información personal y preferencias.

**Componentes principales:**
- Formulario de edición de perfil
- Selección de frase personal (slogan)
- Opción de cierre de sesión

**Funcionalidades:**
- Edición de nombre y apellido
- Selección de slogan personalizado
- Cierre de sesión seguro
- Sincronización con el backend

```dart
Future<void> _actualizarDatos() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = false);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) return;
    final slogan = _selectedSlogan == ""
        ? _availableSlogans[0]
        : _selectedSlogan;
    await _apiService.put('/users/$userId/profile/edit', data: {
      'nombre': _nombreController.text,
      'apellido': _apellidoController.text,
      'slogan': slogan,
    });

    await prefs.setString('nombre', _nombreController.text);
    await prefs.setString('apellido', _apellidoController.text);
    await prefs.setString('slogan', _selectedSlogan);

    widget.onUpdateComplete();
  } catch (e) {
    notificationService.showError(
      context,
      'Error al actualizar los datos',
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## Modelos de Datos

### UserAction

Representa una acción ambiental realizada por un usuario.

```dart
class UserAction {
  final String id;
  final String userId;
  final String tipoAccion;
  final String foto;
  final double latitud;
  final double longitud;
  final String ciudad;
  final String lugar;
  final bool enColaboracion;
  final List<String>? colaboradores;
  final bool esParaTorneo;
  final String? idTorneo;
  final DateTime createdAt;
  final DateTime? deletedAt;
  
  // Constructor y métodos
}
```

### UserAccess

Gestiona la información de acceso y autenticación del usuario.

```dart
class UserAccess {
  final String id;
  final String username;
  final bool isPersonalInformation;
  
  // Constructor y métodos
}
```

### UserBasicInfo

Almacena la información personal básica del usuario.

```dart
class UserBasicInfo {
  final String nombre;
  final String apellido;
  final String telefono;
  final String friendId;
  
  // Constructor y métodos
}
```

### UserProfile

Contiene la información del perfil del usuario, incluyendo la personalización del avatar.

```dart
class UserProfile {
  final String id;
  final String userId;
  final String slogan;
  final String cabello;
  final String vestimenta;
  final String barba;
  final String detalleFacial;
  final String detalleAdicional;
  
  // Constructor y métodos
}
```

### UserStats

Almacena las estadísticas del usuario en la aplicación.

```dart
class UserStats {
  final String id;
  final String userId;
  final int puntos;
  final int acciones;
  final int torneosParticipados;
  final int torneosGanados;
  final int cantidadAmigos;
  final bool esDuenoTorneo;
  final int pendingMedalla;
  final int pendingAmigos;
  final String? torneoId;
  
  // Constructor y métodos
}
```

## Servicios

### ApiService

Gestiona todas las comunicaciones con el backend.

**Archivo**: `lib/services/api_service.dart`

**Funcionalidades principales:**
- Peticiones HTTP (GET, POST, PUT, DELETE)
- Manejo de errores y respuestas
- Parseo de datos
- Gestión de tokens de autenticación

### NotificationService

Gestiona las notificaciones visuales dentro de la aplicación.

**Archivo**: `lib/services/notification_service.dart`

**Tipos de notificaciones:**
- Éxito
- Error
- Información
- Advertencia

### LocationService

Proporciona servicios de geolocalización y búsqueda de lugares.

**Archivo**: `lib/services/location_service.dart`

**Funcionalidades principales:**
- Búsqueda de ubicaciones por nombre
- Obtención de coordenadas
- Filtrado por proximidad

```dart
Future<List<Map<String, dynamic>>> searchLocation(String query,
    {LatLng? nearLocation}) async {
  try {
    final queryParams = {
      'q': query,
      'format': 'json',
      'limit': 5,
      'countrycodes': 'mx',
      'accept-language': 'es',
    };

    // Si hay una ubicación cercana, agregamos un área de búsqueda
    if (nearLocation != null) {
      // Definimos un cuadro de aproximadamente 50km alrededor del punto
      final viewBox = [
        nearLocation.longitude - 0.5, // ~50km oeste
        nearLocation.latitude - 0.5, // ~50km sur
        nearLocation.longitude + 0.5, // ~50km este
        nearLocation.latitude + 0.5, // ~50km norte
      ].join(',');

      queryParams['viewbox'] = viewBox;
      queryParams['bounded'] = '1';
    }

    final response = await _dio.get(
      '$_baseUrl/search',
      queryParameters: queryParams,
      options: Options(
        headers: {
          'User-Agent': 'ProyectoVerdeParticipativo/1.0',
        },
      ),
    );

    // Procesamiento de resultados
    // ...
  } catch (e) {
    print('Error buscando ubicación: $e');
    return [];
  }
}
```

## Autenticación y Seguridad

### Sistema de Autenticación

La aplicación utiliza un sistema de autenticación basado en correo electrónico y contraseña.

**Archivos principales:**
- `lib/widgets/login_bottom_sheet.dart`
- `lib/widgets/registro_bottom_sheet.dart`
- `lib/utils/functions.dart` (para hash de contraseñas)

**Características:**
- Hash seguro de contraseñas (SHA-256)
- Almacenamiento de sesión mediante SharedPreferences
- Relogin automático al iniciar la aplicación

```dart
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### Verificación de Sesión

Al iniciar la aplicación, se verifica si existe una sesión activa.

```dart
Future<Widget> checkInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  final apiService = ApiService();

  if (userId == null) return const WelcomePage();

  try {
    final dataAnswer = await apiService.get(
      '/auth/relogin/$userId',
      parser: (data) => UserAccess.fromJson(data),
    );

    // Obtener información adicional del usuario
    if (dataAnswer.isPersonalInformation) {
      final userInfo = await apiService.get(
        '/users/${dataAnswer.id}/basic-info',
        parser: (data) => UserBasicInfo.fromJson(data),
      );
      // Guardar información personal si existe
      await prefs.setString('nombre', userInfo.nombre);
      await prefs.setString('apellido', userInfo.apellido);
      await prefs.setString('telefono', userInfo.telefono);
      await prefs.setString('friendId', userInfo.friendId);
    }

    // Guardar información básica de autenticación
    await prefs.setString('userId', dataAnswer.id);
    await prefs.setString('username', dataAnswer.username);
    await prefs.setBool(
        'isPersonalInformation', dataAnswer.isPersonalInformation);

    if (dataAnswer.isPersonalInformation) {
      return HomePage(key: HomePage.homeKey);
    } else {
      return const PersonalInfoPage();
    }
  } catch (_) {
    return const WelcomePage();
  }
}
```

## Flujos de Navegación

### Flujo de Inicio

1. La aplicación verifica si existe una sesión activa
2. Si no hay sesión, muestra la pantalla de bienvenida (WelcomePage)
3. Si hay sesión pero falta información personal, muestra PersonalInfoPage
4. Si la sesión es completa, muestra la pantalla principal (HomePage)

### Flujo de Registro

1. Usuario accede a la pantalla de bienvenida
2. Selecciona "Registrarse"
3. Completa el formulario con correo y contraseña
4. Al registrarse exitosamente, se le redirige al formulario de inicio de sesión
5. Tras iniciar sesión, completa su información personal
6. Accede a la pantalla principal

### Flujo de Acción Ambiental

1. Usuario accede a la opción de registrar acción
2. Selecciona el tipo de acción
3. Toma una foto como evidencia
4. Selecciona ubicación
5. Indica si es colaborativa y con quién
6. Envía la acción
7. Recibe puntos y posibles medallas

### Flujo de Personalización

1. Usuario accede a la opción de personalizar avatar
2. Selecciona las características deseadas
3. Guarda los cambios
4. Los cambios se reflejan en toda la aplicación