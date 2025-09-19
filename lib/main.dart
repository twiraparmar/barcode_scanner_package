import 'package:flutter/material.dart';
import 'package:test_package/src/barcode_scanner.dart'; // your custom widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Barcode Scanner Test')),
        body: BarcodeScanner(
          onScan: (result) {
            print("✅ Barcode scanned: ${result.rawValue}, format: ${result.format}");
          },
          onError: (e) {
            print("❌ Error: $e");
          },
        ),
      ),
    );
  }
}
