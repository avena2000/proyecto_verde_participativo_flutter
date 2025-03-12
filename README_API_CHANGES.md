# Cambios en el Servicio API

## Nuevo formato de respuesta estandarizado

Se ha implementado un nuevo formato de respuesta estandarizado para todas las peticiones API. Ahora todas las respuestas del servidor tendrán la siguiente estructura:

```json
{
  "code": "000",
  "message": "Mensaje descriptivo de la operación",
  "data": {
    // Datos de la respuesta (opcional)
  }
}
```

## Códigos de respuesta

Se han definido los siguientes códigos de respuesta:

- **000**: Operación exitosa
- **4xx**: Errores del cliente
  - **400**: Solicitud incorrecta
  - **401**: No autorizado
  - **403**: Prohibido
  - **404**: Recurso no encontrado
  - **405**: Método no permitido
  - **409**: Conflicto con el estado actual del recurso
  - **422**: Error de validación
- **5xx**: Errores del servidor
  - **500**: Error interno del servidor
  - **503**: Servicio no disponible
  - **510**: Error de base de datos
- **6xx**: Códigos personalizados para la aplicación
  - **601**: El usuario ya existe
  - **602**: Credenciales inválidas
  - **603**: No se pudo crear el recurso
  - **604**: No se pudo actualizar el recurso
  - **605**: No se pudo eliminar el recurso
  - **606**: Error al subir la imagen
  - **607**: Error relacionado con torneos
  - **608**: Error relacionado con amistades
  - **609**: Error relacionado con medallas

## Cambios en el servicio API

Se han realizado los siguientes cambios en el servicio API:

1. Se ha creado un nuevo modelo `ApiResponse<T>` para manejar las respuestas del servidor.
2. Se ha añadido un parámetro `showMessages` a todos los métodos del servicio API para controlar si se muestran notificaciones de éxito o error.
3. Se ha añadido un método `setContext` para establecer el contexto de Flutter necesario para mostrar notificaciones.
4. Se ha mejorado el manejo de errores para interpretar los nuevos códigos de respuesta.

## Cómo usar el servicio API actualizado

### 1. Establecer el contexto

Es importante establecer el contexto para poder mostrar notificaciones:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ApiService().setContext(context);
  });
}
```

### 2. Realizar peticiones con notificaciones

Para mostrar notificaciones de éxito o error, utiliza el parámetro `showMessages`:

```dart
try {
  final acciones = await ApiService().getAcciones(showMessages: true);
  // Procesar los datos...
} catch (e) {
  // El error ya se muestra en una notificación, pero puedes manejarlo aquí también
}
```

### 3. Realizar peticiones sin notificaciones

Si no deseas mostrar notificaciones, omite el parámetro `showMessages` o establécelo en `false`:

```dart
try {
  final acciones = await ApiService().getAcciones();
  // Procesar los datos...
} catch (e) {
  // Manejar el error manualmente
}
```

## Archivos modificados

1. `lib/services/api_service.dart`: Servicio API principal
2. `lib/models/api_response.dart`: Nuevo modelo para las respuestas API
3. `lib/constants/api_codes.dart`: Constantes para los códigos de respuesta
4. `lib/examples/api_service_usage_example.dart`: Ejemplo de uso del servicio API actualizado

## Ejemplo de implementación

Se ha creado un archivo de ejemplo `lib/examples/api_service_usage_example.dart` que muestra cómo utilizar el servicio API actualizado. Este ejemplo incluye:

- Establecimiento del contexto
- Carga de datos con notificaciones
- Manejo de errores
- Visualización de los datos en una lista 