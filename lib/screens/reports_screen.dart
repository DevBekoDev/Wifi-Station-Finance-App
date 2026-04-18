import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  final String centerId;

  const ReportsScreen({
    super.key,
    required this.centerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: Center(
        child: Text("Reports screen for center: $centerId"),
      ),
    );
  }
}