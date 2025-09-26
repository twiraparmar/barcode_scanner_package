import 'package:flutter/material.dart';
import 'package:barcode_scanner_package/barcode_scanner_package.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BarcodeScannerPage(),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String? _scannedValue;
  BarcodeFormat? _scannedFormat;
  bool _showCustomScanner = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: Icon(_showCustomScanner ? Icons.settings : Icons.tune),
            onPressed: () {
              setState(() {
                _showCustomScanner = !_showCustomScanner;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showCustomScanner
                ? _buildCustomScanner()
                : _buildDefaultScanner(),
          ),
          if (_scannedValue != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Scanned:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Value: $_scannedValue'),
                  Text('Format: $_scannedFormat'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultScanner() {
    return BarcodeScanner(
      formats: [BarcodeFormat.all],
      cameraFacing: CameraFacing.back,
      onScan: _handleScan,
      onError: _handleError,
    );
  }

  Widget _buildCustomScanner() {
    return BarcodeScanner(
      formats: [BarcodeFormat.all],
      cameraFacing: CameraFacing.back,
      scanningLineColor: Colors.blue,
      scanningLineHeight: 3.0,
      scanningLineDuration: Duration(seconds: 3),
      cornerBracketColor: Colors.blue,
      cornerBracketWidth: 4.0,
      scanningAreaSize: 300.0,
      overlayColor: Colors.black54,
      scanningInstructionText: 'Custom: Position barcode in the blue frame',
      showInstructions: true,
      showScanningLine: true,
      onScan: _handleScan,
      onError: _handleError,
    );
  }

  void _handleScan(BarcodeResult result) {
    setState(() {
      _scannedValue = result.rawValue;
      _scannedFormat = result.format;
    });

    // Show a dialog with the scanned result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Barcode Scanned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Value: ${result.rawValue}'),
            Text('Format: ${result.format}'),
            if (result.displayValue != null)
              Text('Display: ${result.displayValue}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleError(Exception error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
