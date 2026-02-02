🗓️ Planificación del TFG (Semana a Semana)
Fase 1: Cimientos y Diseño
  Semana 1: Diseño de Datos y Prototipado (UI/UX)

  Repo Back: Definir el schema.sql final. Configurar el proyecto Spring Boot básico.
  
  Repo Front: Diseñar en papel o Figma las 3 pantallas clave: Login, Escáner QR y Confirmación.
  
  Meta: Tener los dos repositorios conectados y el entorno de desarrollo listo.
  
Semana 2: El Corazón del Backend (API)
  
  Repo Back: Crear las Entidades (Java) y Repositorios (JPA). Configurar la conexión a la base de datos (MySQL/PostgreSQL).
  
  Repo Front: Crear la navegación básica en Flutter (cambiar de pantalla).
  
  Meta: Que el Backend pueda guardar un alumno manualmente en la DB.

Fase 2: Desarrollo del Flujo Principal
Semana 3: Autenticación (Login)

  Repo Back: Crear el endpoint de Login.
  
  Repo Front: Formulario de login en Flutter y conexión con la API para recibir el token o ID del alumno.
  
  Meta: Un alumno puede loguearse desde el móvil.
  
Semana 4: Implementación del QR (Front)

  Repo Front: Instalar librerías de cámara y escaneo de QR. Lógica para extraer el id_clase del código QR.
  
  Repo Back: Crear el endpoint POST /asistencias/registrar.
  
  Meta: Que la cámara del móvil lea un código y "entienda" qué clase es.

Semana 5: Registro de Asistencia (La "Magia")

  Repo Back: Lógica para guardar la asistencia con la fecha/hora del servidor.
  
  Repo Front: Enviar el ID del alumno + ID de la clase al Back al escanear.
  
  Meta: Flujo completo: Escaneo -> Base de Datos -> Confirmación en pantalla.

Fase 3: Pulido y Extras
Semana 6: Panel del Profesor y Seguridad

  Repo Back: Crear un endpoint para que el profesor vea la lista de alumnos que han entrado.
  
  Repo Front (Opcional): Una pequeña vista web o en la misma app para el profesor.
  
  Meta: Validar que un alumno no pueda firmar dos veces la misma clase el mismo día.

Semana 7: Testing y Errores

  Ambos: Probar qué pasa si no hay internet, si el QR es falso o si el alumno no existe.
  
  Repo Back: Limpieza de código y comentarios.

Semana 8: Documentación Final

  Repo Back/Front: Completar los README.md con instrucciones de instalación.

Memoria: Terminar de escribir la memoria del TFG basándose en lo que has subido a GitHub.
