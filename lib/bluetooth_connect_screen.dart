import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data_screen.dart';

class BluetoothConnectScreen extends StatefulWidget {
  const BluetoothConnectScreen({super.key});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
  bool isScanning = false;
  bool isConnected = false;
  String connectionMessage = "";

  BluetoothCharacteristic? txCharacteristic;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> connectToBT05() async {
    setState(() {
      isScanning = true;
      connectionMessage = "";
    });

    _showSnackbar("🔍 Skanowanie urządzeń...");
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();

    List<ScanResult> results = [];
    await for (var resultList in FlutterBluePlus.scanResults) {
      results = resultList;
      break;
    }

    for (ScanResult r in results) {
      print("Znaleziono: ${r.device.name} | MAC: ${r.device.id}");

      if (r.device.id.id == "D4:F5:13:FB:01:29") {
        _showSnackbar("🔗 Łączenie z BT05...");
        try {
          await r.device.connect();
          setState(() {
            isConnected = true;
            isScanning = false;
            connectionMessage = "Połączono!";
          });

          final services = await r.device.discoverServices();
          for (var service in services) {
            for (var char in service.characteristics) {
              if (char.uuid.toString().toLowerCase().contains("ffe1") &&
                  (char.properties.write || char.properties.writeWithoutResponse)) {
                txCharacteristic = char;
                break;
              }
            }
          }

          if (txCharacteristic != null) {
            _showSnackbar("✅ Połączono z BT05 i znaleziono FFE1");
          } else {
            _showSnackbar("⚠️ Brak charakterystyki FFE1");
          }

          // Nawiguj do DataScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DataScreen(
                connectedDevice: r.device,
                txCharacteristic: txCharacteristic,
              ),
            ),
          );
        } catch (e) {
          _showSnackbar("❌ Błąd połączenia: $e");
          setState(() {
            isScanning = false;
            connectionMessage = "Błąd połączenia.";
          });
        }
        return;
      }
    }

    _showSnackbar("❌ Nie znaleziono BT05!");
    setState(() {
      isScanning = false;
      connectionMessage = "Nie znaleziono urządzenia BT05.";
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth, size: 150, color: Colors.blue),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isScanning ? null : connectToBT05,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: const Color.fromARGB(255, 98, 180, 247),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80)),
              ),
              child: Text(
                isScanning ? "Skanowanie..." : (isConnected ? "Połączono!" : "CONNECT"),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            if (connectionMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    connectionMessage,
                    style: TextStyle(
                      color: connectionMessage.contains("Błąd") || connectionMessage.contains("Nie znaleziono")
                          ? Colors.redAccent
                          : Colors.black87,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
