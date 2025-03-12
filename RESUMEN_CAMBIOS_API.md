# Resumen de Cambios en la Implementación de la API

## Cambios Realizados

Se ha implementado un nuevo formato de respuesta estandarizado para todas las peticiones API. Ahora todas las respuestas del servidor tienen la siguiente estructura:

```json
{
  "code": "000",
  "message": "Mensaje descriptivo de la operación",
  "data": {
    // Datos de la respuesta (opcional)
  }
}
```

### Archivos Creados

1. **lib/constants/api_codes.dart**: Constantes para los códigos de respuesta API.
2. **lib/models/api_response.dart**: Modelo para manejar las respuestas API estandarizadas.
3. **lib/examples/api_service_usage_example.dart**: Ejemplo de uso del servicio API actualizado.
4. **README_API_CHANGES.md**: Documentación detallada de los cambios realizados.

### Archivos Modificados

1. **lib/services/api_service.dart**: 
   - Se agregó soporte para el nuevo formato de respuesta
   - Se implementó el parámetro `showMessages` en todos los métodos
   - Se agregó un método para establecer el contexto para mostrar notificaciones
   - Se mejoró el manejo de errores

2. **lib/providers/acciones_provider.dart**:
   - Se actualizaron los métodos para usar el nuevo formato de respuesta
   - Se agregó el parámetro `showMessages` a todos los métodos

3. **lib/providers/medallas_provider.dart**:
   - Se actualizaron los métodos para usar el nuevo formato de respuesta
   - Se agregó el parámetro `showMessages` a todos los métodos

4. **lib/providers/personaje_provider.dart**:
   - Se actualizaron los métodos para usar el nuevo formato de respuesta
   - Se agregó el parámetro `showMessages` a todos los métodos

5. **lib/screens/medallas_page.dart**:
   - Se convirtió a StatefulWidget para manejar el contexto
   - Se actualizó para usar el nuevo formato de respuesta
   - Se mejoró la interfaz de usuario

## Cómo Usar el Nuevo Sistema

### 1. Establecer el Contexto

Para mostrar notificaciones, es necesario establecer el contexto:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ApiService().setContext(context);
  });
}
```

### 2. Realizar Peticiones con Notificaciones

Para mostrar notificaciones de éxito o error, utiliza el parámetro `showMessages`:

```dart
try {
  final acciones = await ApiService().getAcciones(showMessages: true);
  // Procesar los datos...
} catch (e) {
  // El error ya se muestra en una notificación, pero puedes manejarlo aquí también
}
```

### 3. Realizar Peticiones sin Notificaciones

Si no deseas mostrar notificaciones, omite el parámetro `showMessages` o establécelo en `false`:

```dart
try {
  final acciones = await ApiService().getAcciones();
  // Procesar los datos...
} catch (e) {
  // Manejar el error manualmente
}
```

## Códigos de Respuesta

Se han definido los siguientes códigos de respuesta:

- **000**: Operación exitosa
- **4xx**: Errores del cliente (400, 401, 403, 404, 405, 409, 422)
- **5xx**: Errores del servidor (500, 503, 510)
- **6xx**: Códigos personalizados para la aplicación (601-609)

Cada código tiene un mensaje genérico asociado que se muestra automáticamente si no hay un mensaje específico en la respuesta.

## Beneficios del Nuevo Sistema

1. **Consistencia**: Todas las respuestas tienen el mismo formato, lo que facilita su procesamiento.
2. **Mejor manejo de errores**: Los errores se manejan de manera uniforme en toda la aplicación.
3. **Notificaciones automáticas**: Las notificaciones de éxito o error se muestran automáticamente si se habilita.
4. **Código más limpio**: El código es más limpio y mantenible al centralizar el manejo de respuestas y errores. 