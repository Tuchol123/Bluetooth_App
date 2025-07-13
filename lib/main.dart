import 'package:flutter/material.dart';
import 'bluetooth_connect_screen.dart'; // Importuj ekran połączenia

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemetry App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothConnectScreen(), // To będzie pierwszy ekran
    );
  }
}
