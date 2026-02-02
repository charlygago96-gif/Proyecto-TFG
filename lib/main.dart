import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: SoloUnCampo()));

class SoloUnCampo extends StatefulWidget {
  const SoloUnCampo({super.key});

  @override
  State<SoloUnCampo> createState() => _SoloUnCampoState();
}

class _SoloUnCampoState extends State<SoloUnCampo> {
  String? errorTexto;
  final TextEditingController _controller = TextEditingController();

  void validar() {
    setState(() {
      if (_controller.text.isEmpty) {
        errorTexto = "Campo obligatorio";
      } else {
        errorTexto = null;
      }
      if (_controller.text.length > 10){
        errorTexto = "No puede medir mas de 10 caracteres";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Escribe algo",
                errorText: errorTexto, 
                border: const OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: validar,
              child: const Text("Validar ahora"),
            ),
          ],
        ),
      ),
    );
  }
}