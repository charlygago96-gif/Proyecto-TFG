🗓️ Roadmap TFG: Sistema de Asistencia QR (4 Semanas)
Semana 1: Cimientos y Conectividad (El "Esqueleto")
El objetivo es que el móvil y el servidor se saluden.

Backend (Java/Spring Boot):

Configurar el proyecto en Spring Initializr.

Crear la base de datos SQL con las 3 tablas (Alumnos, Clases, Asistencias).

Crear la entidad Alumno y un endpoint GET /test para verificar que el servidor responde.

Frontend (Flutter):

Crear la estructura del proyecto y la pantalla de Login (solo diseño).

Configurar la librería http para conectar con el Back.

Meta: Hacer una petición desde el móvil y recibir un "Hola Mundo" desde Java.

Semana 2: Autenticación y Generación de QR
Backend:

Endpoint de Login: Recibe correo/pass y devuelve el id_alumno.

Crear un pequeño script o vista que genere un QR con un id_clase (puedes usar una web externa para generar el QR manualmente por ahora).

Frontend:

Lógica de Login: Guardar el id_alumno localmente (SharedPreferences).

Implementar la cámara con mobile_scanner.

Meta: Loguearse en la app y que la cámara reconozca un código QR.

Semana 3: El Flujo Maestro (Registro de Asistencia)
Esta es la semana clave donde todo se une.

Backend:

Crear endpoint POST /asistencias/registrar.

Lógica: Recibir id_alumno e id_clase, validar que existen y guardar en la tabla asistencias con el TIMESTAMP actual.

Frontend:

Al escanear el QR, enviar automáticamente la petición al Back.

Mostrar pantalla de "¡Asistencia registrada con éxito!" o "Error".

Meta: Escanear un QR y ver una nueva fila aparecer en tu base de datos SQL automáticamente.

Semana 4: Pulido, Seguridad y Memoria
Backend:

Añadir una validación simple: "Si el alumno ya firmó en esta clase hoy, no dejarle firmar otra vez".

Frontend:

Validar campos vacíos en el login y mejorar un poco el diseño (colores, logo).

Documentación (TFG):

Exportar el diagrama de la base de datos.

Documentar los Endpoints (puedes usar Swagger o simplemente una lista en Markdown).

Grabar el video de demostración (¡muy importante para la nota!).
