# Asistencia TFG - App móvil

Aplicación móvil desarrollada con Flutter para la gestión de asistencia a exámenes mediante códigos QR.

## ¿Qué hace?

- Los **profesores** crean exámenes, asignan alumnos y generan un código QR
- Los **alumnos** escanean el QR para registrar su asistencia
- El profesor ve en tiempo real quién ha asistido y quién no
- Los alumnos reciben una **notificación push 1 hora antes** del examen

## Tecnologías

- Flutter / Dart
- Firebase (notificaciones push con FCM)
- Escáner QR con `mobile_scanner`
- Generación de QR con `qr_flutter`
- Comunicación con backend REST via HTTP

## Backend

El backend está en un repositorio separado: [Proyecto-TFG-Backend](https://github.com/charlygago96-gif/Proyecto-TFG-Backend)
