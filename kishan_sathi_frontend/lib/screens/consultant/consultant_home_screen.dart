import 'package:flutter/material.dart';

class ConsultantHomeScreen extends StatelessWidget {
  const ConsultantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultant Home')),
      body: const Center(
        child: Text('Welcome to the consultant dashboard.'),
      ),
    );
  }
}
