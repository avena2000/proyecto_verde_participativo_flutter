class ApiCodes {
  // Códigos de éxito
  static const String codeSuccess = "000"; // Operación exitosa

  // Códigos de error de cliente (4xx)
  static const String codeBadRequest = "400"; // Solicitud incorrecta
  static const String codeUnauthorized = "401"; // No autorizado
  static const String codeForbidden = "403"; // Prohibido
  static const String codeNotFound = "404"; // Recurso no encontrado
  static const String codeMethodNotAllowed = "405"; // Método no permitido
  static const String codeConflict =
      "409"; // Conflicto con el estado actual del recurso
  static const String codeValidationError = "422"; // Error de validación

  // Códigos de error de servidor (5xx)
  static const String codeInternalServerError =
      "500"; // Error interno del servidor
  static const String codeServiceUnavailable = "503"; // Servicio no disponible
  static const String codeDatabaseError = "510"; // Error de base de datos

  // Códigos personalizados para la aplicación
  static const String codeUserAlreadyExists = "601"; // El usuario ya existe
  static const String codeInvalidCredentials = "602"; // Credenciales inválidas
  static const String codeResourceNotCreated =
      "603"; // No se pudo crear el recurso
  static const String codeResourceNotUpdated =
      "604"; // No se pudo actualizar el recurso
  static const String codeResourceNotDeleted =
      "605"; // No se pudo eliminar el recurso
  static const String codeImageUploadError = "606"; // Error al subir la imagen
  static const String codeTournamentError =
      "607"; // Error relacionado con torneos
  static const String codeFriendshipError =
      "608"; // Error relacionado con amistades
  static const String codeMedalError = "609"; // Error relacionado con medallas

  // Mensajes genéricos por código
  static String getMessageForCode(String code) {
    switch (code) {
      case codeSuccess:
        return "Operación exitosa";
      case codeBadRequest:
        return "Solicitud incorrecta";
      case codeUnauthorized:
        return "No autorizado";
      case codeForbidden:
        return "Acceso denegado";
      case codeNotFound:
        return "Recurso no encontrado";
      case codeMethodNotAllowed:
        return "Método no permitido";
      case codeConflict:
        return "Conflicto con el recurso";
      case codeValidationError:
        return "Error de validación";
      case codeInternalServerError:
        return "Error interno del servidor";
      case codeServiceUnavailable:
        return "Servicio no disponible";
      case codeDatabaseError:
        return "Error en la base de datos";
      case codeUserAlreadyExists:
        return "El usuario ya existe";
      case codeInvalidCredentials:
        return "Credenciales inválidas";
      case codeResourceNotCreated:
        return "No se pudo crear el recurso";
      case codeResourceNotUpdated:
        return "No se pudo actualizar el recurso";
      case codeResourceNotDeleted:
        return "No se pudo eliminar el recurso";
      case codeImageUploadError:
        return "Error al subir la imagen";
      case codeTournamentError:
        return "Error en el torneo";
      case codeFriendshipError:
        return "Error en la solicitud de amistad";
      case codeMedalError:
        return "Error relacionado con medallas";
      default:
        return "Error desconocido";
    }
  }
}
