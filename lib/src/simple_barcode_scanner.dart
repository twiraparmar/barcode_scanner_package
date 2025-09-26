import 'package:flutter/material.dart';
import 'barcode_scanner.dart';
import 'barcode_types.dart';

/// A simple barcode scanner widget that returns scanned values
class SimpleBarcodeScanner extends StatefulWidget {
  final List<BarcodeFormat> formats;
  final CameraFacing cameraFacing;
  final Duration scanInterval;
  final Function(BarcodeResult)? onScan;
  final Function(Exception)? onError;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  // Customization options
  final Color scanningLineColor;
  final double scanningLineHeight;
  final Duration scanningLineDuration;
  final Color cornerBracketColor;
  final double cornerBracketWidth;
  final double scanningAreaSize;
  final Color overlayColor;
  final String scanningInstructionText;
  final bool showInstructions;
  final bool showScanningLine;

  const SimpleBarcodeScanner({
    super.key,
    this.formats = const [BarcodeFormat.all],
    this.cameraFacing = CameraFacing.back,
    this.scanInterval = const Duration(milliseconds: 1000),
    this.onScan,
    this.onError,
    this.loadingWidget,
    this.errorWidget,
    this.scanningLineColor = Colors.green,
    this.scanningLineHeight = 2.0,
    this.scanningLineDuration = const Duration(seconds: 2),
    this.cornerBracketColor = Colors.green,
    this.cornerBracketWidth = 3.0,
    this.scanningAreaSize = 250.0,
    this.overlayColor = Colors.black,
    this.scanningInstructionText = 'Position barcode within the frame',
    this.showInstructions = true,
    this.showScanningLine = true,
  });

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  BarcodeResult? _lastScannedResult;
  String? _scannedValue;
  BarcodeFormat? _scannedFormat;
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return BarcodeScanner(
      formats: widget.formats,
      cameraFacing: widget.cameraFacing,
      scanInterval: widget.scanInterval,
      scanningLineColor: widget.scanningLineColor,
      scanningLineHeight: widget.scanningLineHeight,
      scanningLineDuration: widget.scanningLineDuration,
      cornerBracketColor: widget.cornerBracketColor,
      cornerBracketWidth: widget.cornerBracketWidth,
      scanningAreaSize: widget.scanningAreaSize,
      overlayColor: widget.overlayColor,
      scanningInstructionText: widget.scanningInstructionText,
      showInstructions: widget.showInstructions,
      showScanningLine: widget.showScanningLine,
      onScan: (BarcodeResult result) {
        setState(() {
          _lastScannedResult = result;
          _scannedValue = result.rawValue;
          _scannedFormat = result.format;
        });
        widget.onScan?.call(result);
      },
      onError: (Exception error) {
        widget.onError?.call(error);
      },
      loadingWidget: widget.loadingWidget,
      errorWidget: widget.errorWidget,
    );
  }

  /// Get the last scanned result
  BarcodeResult? get lastScannedResult => _lastScannedResult;

  /// Get the last scanned value as string
  String? get scannedValue => _scannedValue;

  /// Get the last scanned format
  BarcodeFormat? get scannedFormat => _scannedFormat;

  /// Check if scanner is currently scanning
  bool get isScanning => _isScanning;

  /// Stop scanning
  void stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  /// Start scanning
  void startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  /// Clear the last scanned result
  void clearResult() {
    setState(() {
      _lastScannedResult = null;
      _scannedValue = null;
      _scannedFormat = null;
    });
  }
}

