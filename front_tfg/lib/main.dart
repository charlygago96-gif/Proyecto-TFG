import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

// --- CONFIGURACIÓN GLOBAL ---
const String apiBaseUrl = "http://localhost:9000/api/tfg";
void main() {
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

// --- 1. PANTALLA DE LOGIN ---
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
          .timeout(const Duration(seconds: 5));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _mostrarAlerta(context, "Error de acceso",
            "Credenciales incorrectas o usuario no activo");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarAlerta(context, "Error de Conexión",
          "No se pudo conectar con el servidor en $apiBaseUrl. ¿Está Spring Boot encendido?");
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
            const Icon(Icons.lock_person, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text("Acceso TFG",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
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

// --- 2. PANTALLA DE REGISTRO ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
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
              "correo": _emailController.text.trim(),
              "password": _passController.text,
              "rol": _rolSeleccionado,
              "activo": true,
              "codigo":
                  "USER-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
              "hora": DateTime.now()
                  .toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _mostrarAlerta(context, "Éxito", "Usuario registrado correctamente");
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
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value!.contains('@') ? null : "Email no válido",
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Contraseña", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.length < 4 ? "Mínimo 4 caracteres" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Repetir Contraseña",
                    border: OutlineInputBorder()),
                validator: (value) =>
                    value != _passController.text ? "No coinciden" : null,
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

// --- 3. PANTALLA PRINCIPAL ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginPage())),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _menuButton(context, "Panel Profesor (CRUD)", Icons.school,
                const ProfesorPage()),
            const SizedBox(height: 20),
            _menuButton(context, "Escanear QR (Alumno)", Icons.qr_code_scanner,
                const AlumnoPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
      BuildContext context, String text, IconData icon, Widget page) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

// --- 4. VISTA PROFESOR (CRUD) ---
class ProfesorPage extends StatefulWidget {
  const ProfesorPage({super.key});

  @override
  State<ProfesorPage> createState() => _ProfesorPageState();
}

class _ProfesorPageState extends State<ProfesorPage> {
  List examenes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarExamenes();
  }

  Future<void> cargarExamenes() async {
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/todos"));
      if (response.statusCode == 200) {
        setState(() {
          examenes = json.decode(response.body);
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }
Future<void> crearExamen(String nombre) async {
  await http.post(
    Uri.parse("$apiBaseUrl/crear-examen"),
    body: jsonEncode({
      "nombre": nombre,
      "codigoExamen": "EXAM-${DateTime.now().millisecondsSinceEpoch}",
      "profesor": "correo@profesor.com",
      "alumnosAsignados": ["alumno1@gmail.com", "alumno2@gmail.com"] // Lista de correos
    }),
  );
}
  Future<void> eliminar(String codigo) async {
    try {
      final response =
          await http.delete(Uri.parse("$apiBaseUrl/eliminar/$codigo"));
      if (response.statusCode == 200) cargarExamenes();
    } catch (e) {
      _showSnack("Error al eliminar");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: examenes.length,
              itemBuilder: (context, i) {
                final item = examenes[i];
                return Card(
                  child: ListTile(
                    title: Text("Cod: ${item['codigo']}"),
                    subtitle: Text(item['correo']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.qr_code),
                            onPressed: () => _verQR(context, item['codigo'])),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => eliminar(item['codigo'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _verQR(BuildContext context, String data) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Asistencia QR"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                QrImageView(data: data, size: 200),
                const SizedBox(height: 10),
                Text(data, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ));
  }
}

// --- 5. VISTA ALUMNO (ESCÁNER) ---
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
      appBar: AppBar(title: const Text("Escanear Código")),
      body: MobileScanner(
        onDetect: (capture) {
          if (!scaneado && capture.barcodes.isNotEmpty) {
            scaneado = true;
            final String code = capture.barcodes.first.rawValue ?? "---";
            _registrarAsistencia(code);
          }
        },
      ),
    );
  }
void _mostrarExito(String mensaje) {
  showDialog(
    context: context,
    barrierDismissible: false, // Obliga al usuario a pulsar el botón
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("¡Completado!"),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Regresa a la pantalla de Inicio
            },
            child: const Text("Aceptar"),
          ),
        ],
      );
    },
  );
}
  Future<void> _registrarAsistencia(String codigoExamen) async {
  // Asumiendo que guardaste el correo del alumno al hacer login
  String correoAlumno = "alumno@ejemplo.com"; 

  final response = await http.post(
    Uri.parse("$apiBaseUrl/fichar"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "codigoExamen": codigoExamen,
      "correo": correoAlumno,
      "hora": DateTime.now().toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    _mostrarExito("Asistencia registrada para el examen: $codigoExamen");
  }
}
}

// --- UTILIDADES ---
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
        ]),
  );
}
