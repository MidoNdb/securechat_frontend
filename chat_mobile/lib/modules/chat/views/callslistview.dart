// lib/modules/chat/views/calls_list_view.dart

import 'package:flutter/material.dart';

class CallsListView extends StatelessWidget {
  const CallsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appels'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Historique des appels',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos appels apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}