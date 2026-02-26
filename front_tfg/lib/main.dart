import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// --- CONFIGURACIÓN GLOBAL ---
const String apiBaseUrl =
    "https://proyecto-tfg-backend-production.up.railway.app/api/tfg";

// Handler para notificaciones en segundo plano (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asistencia TFG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// MODELO DE USUARIO
// ============================================================
class UsuarioSesion {
  static String correo = '';
  static String nombre = '';
  static String apellido = '';
  static String rol = '';

  static String get nombreCompleto => '$nombre $apellido'.trim();

  static void clear() {
    correo = '';
    nombre = '';
    apellido = '';
    rol = '';
  }
}

// ============================================================
// 1. PANTALLA DE LOGIN
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnack("Por favor, rellena todos los campos");
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "correo": _emailController.text.trim(),
              "password": _passController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        UsuarioSesion.correo = data['correo'] ?? _emailController.text.trim();
        UsuarioSesion.nombre = data['nombre'] ?? '';
        UsuarioSesion.apellido = data['apellido'] ?? '';
        UsuarioSesion.rol = data['rol'] ?? 'ALUMNO';

        // Obtener token FCM y enviarlo al backend
        await _enviarTokenFCM();

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.waving_hand, color: Colors.amber),
              SizedBox(width: 8),
              Text("¡Bienvenido!"),
            ]),
            content: Text(
              "Has iniciado sesión como:\n\n"
              "👤 ${UsuarioSesion.nombreCompleto}\n"
              "📧 ${UsuarioSesion.correo}\n"
              "🎓 ${UsuarioSesion.rol}",
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Continuar"),
              )
            ],
          ),
        );

        if (!mounted) return;
        if (UsuarioSesion.rol == 'PROFESOR') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeProfesor()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeAlumno()),
          );
        }
      } else {
        _mostrarAlerta(context, "Error de acceso",
            "Credenciales incorrectas o usuario no activo");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarAlerta(
          context, "Error de Conexión", "No se pudo conectar con el servidor.");
    }
  }

  Future<void> _enviarTokenFCM() async {
    try {
      // Pedir permiso de notificaciones
      await FirebaseMessaging.instance.requestPermission();

      // Obtener el token del dispositivo
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse("$apiBaseUrl/fcm-token"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "correo": UsuarioSesion.correo,
            "fcmToken": token,
          }),
        );
        debugPrint("Token FCM enviado: $token");
      }
    } catch (e) {
      // Si falla no bloqueamos el login
      debugPrint("Error enviando token FCM: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Contraseña", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text("Iniciar Sesión"),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text("¿No tienes cuenta? Regístrate"),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 2. PANTALLA DE REGISTRO
// ============================================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String _rolSeleccionado = 'ALUMNO';
  bool _isLoading = false;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/crear"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "nombre": _nombreController.text.trim(),
              "apellido": _apellidoController.text.trim(),
              "correo": _emailController.text.trim(),
              "password": _passController.text,
              "rol": _rolSeleccionado,
              "activo": true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _mostrarAlerta(context, "Éxito", "Usuario registrado correctamente.");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _mostrarAlerta(
            context, "Error", "Error al registrar: ${response.body}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarAlerta(
          context, "Error de Conexión", "No se pudo alcanzar el backend.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 70, color: Colors.indigo),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                    labelText: "Nombre", border: OutlineInputBorder()),
                validator: (v) =>
                    v!.isEmpty ? "El nombre es obligatorio" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                    labelText: "Apellido", border: OutlineInputBorder()),
                validator: (v) =>
                    v!.isEmpty ? "El apellido es obligatorio" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    border: OutlineInputBorder()),
                validator: (v) => v!.contains('@') ? null : "Email no válido",
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Contraseña", border: OutlineInputBorder()),
                validator: (v) => v!.length < 4 ? "Mínimo 4 caracteres" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Repetir Contraseña",
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v != _passController.text ? "No coinciden" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                    labelText: "Tipo de Usuario", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "ALUMNO", child: Text("Alumno")),
                  DropdownMenuItem(value: "PROFESOR", child: Text("Profesor")),
                ],
                onChanged: (val) => setState(() => _rolSeleccionado = val!),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrar,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Registrarse ahora"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. HOME PROFESOR
// ============================================================
class HomeProfesor extends StatelessWidget {
  const HomeProfesor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hola, ${UsuarioSesion.nombreCompleto}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () {
              UsuarioSesion.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.school, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(UsuarioSesion.nombreCompleto,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(UsuarioSesion.correo,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _menuButton(context, "Crear Examen", Icons.add_box, Colors.indigo,
                const CrearExamenPage()),
            const SizedBox(height: 16),
            _menuButton(context, "Gestionar Exámenes", Icons.list_alt,
                Colors.teal, const ProfesorPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String text, IconData icon,
      Color color, Widget page) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white),
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 16)),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

// ============================================================
// 4. HOME ALUMNO
// ============================================================
class HomeAlumno extends StatelessWidget {
  const HomeAlumno({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hola, ${UsuarioSesion.nombreCompleto}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () {
              UsuarioSesion.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(UsuarioSesion.nombreCompleto,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(UsuarioSesion.correo,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _menuButton(context, "Escanear QR", Icons.qr_code_scanner,
                Colors.green, const AlumnoPage()),
            const SizedBox(height: 16),
            _menuButton(context, "Mis Exámenes", Icons.assignment,
                Colors.orange, const ExamenesAlumnoPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String text, IconData icon,
      Color color, Widget page) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white),
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 16)),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

// ============================================================
// 5. CREAR EXAMEN
// ============================================================
class CrearExamenPage extends StatefulWidget {
  const CrearExamenPage({super.key});

  @override
  State<CrearExamenPage> createState() => _CrearExamenPageState();
}

class _CrearExamenPageState extends State<CrearExamenPage> {
  final _nombreExamenController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  List<dynamic> _todosAlumnos = [];
  List<String> _alumnosSeleccionados = [];
  bool _cargandoAlumnos = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/alumnos"));
      if (response.statusCode == 200) {
        setState(() {
          _todosAlumnos = json.decode(response.body);
          _cargandoAlumnos = false;
        });
      }
    } catch (e) {
      setState(() => _cargandoAlumnos = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _horaSeleccionada = picked);
  }

  Future<void> _crearExamen() async {
    if (_nombreExamenController.text.isEmpty) {
      _showSnack("El nombre del examen es obligatorio");
      return;
    }
    if (_fechaSeleccionada == null) {
      _showSnack("Selecciona la fecha del examen");
      return;
    }
    if (_horaSeleccionada == null) {
      _showSnack("Selecciona la hora del examen");
      return;
    }
    if (_alumnosSeleccionados.isEmpty) {
      _showSnack("Selecciona al menos un alumno");
      return;
    }

    setState(() => _guardando = true);

    final fechaCompleta = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/crear-examen"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": _nombreExamenController.text.trim(),
          "codigoExamen": "EXAM-${DateTime.now().millisecondsSinceEpoch}",
          "profesor": UsuarioSesion.correo,
          "fecha": fechaCompleta
              .toUtc()
              .add(const Duration(hours: 1))
              .toIso8601String(),
          "alumnosAsignados": _alumnosSeleccionados,
        }),
      );

      setState(() => _guardando = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _mostrarAlerta(context, "Examen creado",
            "El examen '${_nombreExamenController.text}' ha sido creado. Los alumnos recibirán una notificación 1 hora antes.");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _mostrarAlerta(context, "Error", "No se pudo crear: ${response.body}");
      }
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarAlerta(
          context, "Error de Conexión", "Fallo al contactar con el backend.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Examen")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreExamenController,
              decoration: const InputDecoration(
                labelText: "Nombre del Examen",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(
                      _fechaSeleccionada == null
                          ? "Seleccionar fecha del examen"
                          : "Fecha: ${_formatDate(_fechaSeleccionada!)}",
                      style: TextStyle(
                        color: _fechaSeleccionada == null
                            ? Colors.grey
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _seleccionarHora,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(
                      _horaSeleccionada == null
                          ? "Seleccionar hora del examen"
                          : "Hora: ${_horaSeleccionada!.format(context)}",
                      style: TextStyle(
                        color: _horaSeleccionada == null
                            ? Colors.grey
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_horaSeleccionada != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Los alumnos serán notificados 1h antes",
                      style: TextStyle(
                          color: Colors.orange.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text("Seleccionar Alumnos:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _cargandoAlumnos
                ? const Center(child: CircularProgressIndicator())
                : _todosAlumnos.isEmpty
                    ? const Text("No hay alumnos disponibles",
                        style: TextStyle(color: Colors.grey))
                    : Card(
                        child: Column(
                          children: _todosAlumnos.map((alumno) {
                            final correo = alumno['correo'] as String;
                            final nombre = alumno['nombre'] ?? '';
                            final apellido = alumno['apellido'] ?? '';
                            final seleccionado =
                                _alumnosSeleccionados.contains(correo);
                            return CheckboxListTile(
                              value: seleccionado,
                              title: Text("$nombre $apellido"),
                              subtitle: Text(correo),
                              secondary: CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.indigo),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _alumnosSeleccionados.add(correo);
                                  } else {
                                    _alumnosSeleccionados.remove(correo);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_guardando ? "Creando..." : "Crear Examen"),
                onPressed: _guardando ? null : _crearExamen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. GESTIÓN DE EXÁMENES (PROFESOR)
// ============================================================
class ProfesorPage extends StatefulWidget {
  const ProfesorPage({super.key});

  @override
  State<ProfesorPage> createState() => _ProfesorPageState();
}

class _ProfesorPageState extends State<ProfesorPage> {
  List examenes = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarExamenes();
  }

  Future<void> cargarExamenes() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(
              "$apiBaseUrl/examenes-profesor/${UsuarioSesion.correo}"))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          examenes = json.decode(response.body);
          cargando = false;
        });
      } else {
        setState(() {
          error = "Error: ${response.statusCode}";
          cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Error de conexión";
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Exámenes"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: cargarExamenes)
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 70, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reintentar"),
                        onPressed: cargarExamenes,
                      ),
                    ],
                  ),
                )
              : examenes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 70, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("No tienes exámenes creados",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: examenes.length,
                      itemBuilder: (context, i) {
                        final item = examenes[i];
                        final fechaStr = item['fecha'] != null
                            ? _formatDate(DateTime.parse(item['fecha']))
                            : "Sin fecha";
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetalleExamenPage(examen: item),
                                    ),
                                  );
                                },
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  child: Icon(Icons.assignment,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  item['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("📅 $fechaStr"),
                                    Text(
                                      "🔑 ${item['codigoExamen'] ?? ''}",
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.qr_code,
                                          color: Colors.indigo),
                                      label: const Text("Ver QR",
                                          style:
                                              TextStyle(color: Colors.indigo)),
                                      onPressed: () => _verQR(
                                          context,
                                          item['codigoExamen'] ?? '',
                                          item['nombre'] ?? ''),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      label: const Text("Eliminar",
                                          style: TextStyle(color: Colors.red)),
                                      onPressed: () => _confirmarEliminar(
                                          item['codigoExamen'] ?? '',
                                          item['nombre'] ?? ''),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  void _verQR(BuildContext context, String data, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(nombre.isNotEmpty ? nombre : "QR del Examen"),
        content: SizedBox(
          width: 260,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: QrImageView(
                  data: data.isNotEmpty ? data : "sin-datos",
                  size: 220,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 10),
              Text(data,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"))
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(String codigo, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar examen?"),
        content: Text("Vas a eliminar el examen \"$nombre\"."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirmar == true) _eliminar(codigo);
  }

  Future<void> _eliminar(String codigo) async {
    try {
      final response = await http
          .delete(Uri.parse("$apiBaseUrl/eliminar/$codigo"))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        cargarExamenes();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Examen eliminado correctamente")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error al eliminar")));
    }
  }
}

// ============================================================
// 7. EXÁMENES DEL ALUMNO
// ============================================================
class ExamenesAlumnoPage extends StatefulWidget {
  const ExamenesAlumnoPage({super.key});

  @override
  State<ExamenesAlumnoPage> createState() => _ExamenesAlumnoPageState();
}

class _ExamenesAlumnoPageState extends State<ExamenesAlumnoPage> {
  List examenes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarExamenes();
  }

  Future<void> _cargarExamenes() async {
    try {
      final response = await http.get(
          Uri.parse("$apiBaseUrl/examenes-alumno/${UsuarioSesion.correo}"));
      if (response.statusCode == 200) {
        setState(() {
          examenes = json.decode(response.body);
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Exámenes Asignados"),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargarExamenes)
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : examenes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 70, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("No tienes exámenes asignados",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: examenes.length,
                  itemBuilder: (context, i) {
                    final item = examenes[i];
                    final fechaStr = item['fecha'] != null
                        ? _formatDate(DateTime.parse(item['fecha']))
                        : "Fecha no disponible";
                    final esFuturo = item['fecha'] != null &&
                        DateTime.parse(item['fecha']).isAfter(DateTime.now());
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              esFuturo ? Colors.orange : Colors.grey,
                          child: Icon(
                            esFuturo
                                ? Icons.upcoming
                                : Icons.assignment_turned_in,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                            item['nombre'] ?? item['codigoExamen'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📅 $fechaStr"),
                            Text(
                              esFuturo ? "⏳ Próximo" : "✅ Pasado",
                              style: TextStyle(
                                  color:
                                      esFuturo ? Colors.orange : Colors.grey),
                            ),
                            if (esFuturo)
                              Row(
                                children: [
                                  const Icon(Icons.notifications_active,
                                      size: 13, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Recibirás aviso 1h antes",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================
// 8. VISTA ALUMNO - ESCÁNER QR
// ============================================================
class AlumnoPage extends StatefulWidget {
  const AlumnoPage({super.key});

  @override
  State<AlumnoPage> createState() => _AlumnoPageState();
}

class _AlumnoPageState extends State<AlumnoPage> {
  bool scaneado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Código QR")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!scaneado && capture.barcodes.isNotEmpty) {
                scaneado = true;
                final String code = capture.barcodes.first.rawValue ?? "---";
                _registrarAsistencia(code);
              }
            },
          ),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Apunta la cámara al código QR del examen",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarAsistencia(String codigoExamen) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/fichar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "codigoExamen": codigoExamen,
          "correo": UsuarioSesion.correo,
          "hora": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _mostrarExito("¡Asistencia registrada!\nExamen: $codigoExamen");
      } else {
        if (mounted) {
          _mostrarAlerta(context, "Error",
              "No se pudo registrar la asistencia: ${response.body}");
          setState(() => scaneado = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarAlerta(
            context, "Error de Conexión", "No se pudo contactar al servidor.");
        setState(() => scaneado = false);
      }
    }
  }

  void _mostrarExito(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text("¡Completado!"),
        ]),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 9. DETALLE EXAMEN - PRESENTES Y AUSENTES
// ============================================================
class DetalleExamenPage extends StatefulWidget {
  final Map examen;

  const DetalleExamenPage({super.key, required this.examen});

  @override
  State<DetalleExamenPage> createState() => _DetalleExamenPageState();
}

class _DetalleExamenPageState extends State<DetalleExamenPage> {
  List asistencias = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarAsistencia();
  }

  Future<void> _cargarAsistencia() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(
              "$apiBaseUrl/asistencia-examen/${widget.examen['codigoExamen']}"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          asistencias = json.decode(response.body);
          cargando = false;
        });
      } else {
        setState(() {
          error = "Error al cargar asistencia";
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error de conexión";
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentes =
        asistencias.where((a) => a['haEscaneado'] == true).toList();
    final ausentes =
        asistencias.where((a) => a['haEscaneado'] == false).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examen['nombre'] ?? "Detalle"),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _cargarAsistencia)
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _cargarAsistencia,
                          child: const Text("Reintentar")),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.indigo.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _resumenChip("${presentes.length}", "Presentes",
                                Colors.green),
                            _resumenChip(
                                "${ausentes.length}", "Ausentes", Colors.red),
                            _resumenChip("${asistencias.length}", "Total",
                                Colors.indigo),
                          ],
                        ),
                      ),
                      TabBar(
                        labelColor: Colors.indigo,
                        indicatorColor: Colors.indigo,
                        tabs: [
                          Tab(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              text: "Presentes (${presentes.length})"),
                          Tab(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              text: "Ausentes (${ausentes.length})"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildListaAlumnos(presentes, true),
                            _buildListaAlumnos(ausentes, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _resumenChip(String numero, String label, Color color) {
    return Column(
      children: [
        Text(numero,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildListaAlumnos(List lista, bool esPresente) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esPresente ? Icons.hourglass_empty : Icons.celebration,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              esPresente
                  ? "Ningún alumno ha escaneado aún"
                  : "¡Todos los alumnos han asistido!",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final alumno = lista[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  esPresente ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                esPresente ? Icons.check : Icons.close,
                color: esPresente ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              "${alumno['nombre'] ?? ''} ${alumno['apellido'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(alumno['correo'] ?? ''),
            trailing: esPresente
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Escaneado:",
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        alumno['horaEscaneo'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                            fontSize: 12),
                      ),
                    ],
                  )
                : const Chip(
                    label: Text("Pendiente",
                        style: TextStyle(color: Colors.orange, fontSize: 11)),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.orange),
                  ),
          ),
        );
      },
    );
  }
}

// ============================================================
// HELPERS GLOBALES
// ============================================================
String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

void _mostrarAlerta(BuildContext context, String titulo, String msg) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Text(msg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"))
      ],
    ),
  );
}
