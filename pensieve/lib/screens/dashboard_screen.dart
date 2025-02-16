import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 221, 195, 252),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Color.fromARGB(255, 71, 51, 90)),
        ),
        backgroundColor: const Color.fromARGB(255, 177, 147, 204),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Hola, Juan!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tienes 3 tareas pendientes',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notas más recientes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Aquí irían las notas más recientes
            const SizedBox(height: 16),
            const Text(
              'Documentos más recientes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Aquí irían los documentos más recientes
          ],
        ),
      ),
    );
  }
}