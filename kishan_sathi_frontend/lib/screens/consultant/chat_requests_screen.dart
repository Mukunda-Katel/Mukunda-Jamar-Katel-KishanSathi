import 'package:flutter/material.dart';

class ChatRequestsScreen extends StatelessWidget {
  const ChatRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Requests')),
      body: const Center(
        child: Text('No pending chat requests.'),
      ),
    );
  }
}
