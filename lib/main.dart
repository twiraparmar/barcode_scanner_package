import 'package:flutter/material.dart';

import 'barcode_scanner_package.dart';

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

          },
          onError: (e) {

          },
        ),
      ),
    );
  }
}
