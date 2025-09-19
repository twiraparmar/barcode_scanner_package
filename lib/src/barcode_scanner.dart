

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;

import '../barcode_scanner_flutter.dart' as custom;

class BarcodeScanner extends StatefulWidget {
  final List<custom.BarcodeFormat> formats;
  final custom.CameraFacing cameraFacing;
  final bool autoFocus;
  final bool enableTapToFocus;
  final bool enablePinchToZoom;
  final Duration scanInterval;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final BoxFit fit;
  final Function(custom.BarcodeResult)? onScan;
  final Function(Exception)? onError;

  const BarcodeScanner({
    super.key,
    this.formats = const [custom.BarcodeFormat.all],
    this.cameraFacing = custom.CameraFacing.back,
    this.autoFocus = true,
    this.enableTapToFocus = true,
    this.enablePinchToZoom = true,
    this.scanInterval = const Duration(milliseconds: 500),
    this.loadingWidget,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.onScan,
    this.onError,
  });

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();

  static Future<bool> get hasCamera async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  CameraController? _controller;
  late mlkit.BarcodeScanner _barcodeScanner;
  bool _isInitialized = false;
  bool _hasError = false;
  double _zoomLevel = 1.0;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      // Check camera permission
      if (!await BarcodeScanner.requestCameraPermission()) {
        throw custom.CameraPermissionDeniedException();
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw custom.CameraNotAvailableException();
      }

      // Select camera based on facing
      final camera = cameras.firstWhere(
            (camera) => camera.lensDirection ==
            (widget.cameraFacing == custom.CameraFacing.back
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      // Initialize barcode scanner
// Ensure conversion returns mlkit.BarcodeFormat
      final formats = widget.formats.map((f) => f.toMlKitFormat()).toList().cast<mlkit.BarcodeFormat>();

      _barcodeScanner = mlkit.BarcodeScanner(formats: formats);

      setState(() {
        _isInitialized = true;
      });

      // Start scanning
      _startScanning();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      widget.onError?.call(
        e is custom.BarcodeScannerException ? e : custom.ScannerInitializationException(e),
      );
    }
  }

  void _startScanning() {
    _scanTimer = Timer.periodic(widget.scanInterval, (timer) async {
      if (_controller == null || !_controller!.value.isInitialized) return;

      try {
        final image = await _controller!.takePicture();
        final inputImage = mlkit.InputImage.fromFilePath(image.path);
        final barcodes = await _barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first;
          final result = custom.BarcodeResult(
            rawValue: barcode.rawValue ?? '',
            format: barcode.format.toCustomFormat(),

            displayValue: barcode.displayValue,
          );

          widget.onScan?.call(result);
        }

        // Clean up the image file
        await File(image.path).delete();
      } catch (e) {
        widget.onError?.call(custom.BarcodeScannerException('Scan failed', e));
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (!_isInitialized) {
      return widget.loadingWidget ?? _buildLoadingWidget();
    }

    return Stack(
      children: [
        CameraPreview(_controller!),
        if (widget.enableTapToFocus)
          GestureDetector(
            onTapDown: (details) {
              if (_controller != null) {
                _controller!.setFocusPoint(details.localPosition);
              }
            },
          ),
        if (widget.enablePinchToZoom)
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _zoomLevel = (_zoomLevel * details.scale).clamp(1.0, 8.0);
                _controller!.setZoomLevel(_zoomLevel);
              });
            },
          ),
        // Add overlay or scanning UI here
        _buildScanningOverlay(),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Camera Error', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Please check camera permissions and try again'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeScanner,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withAlpha(1), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(40),
      child: CustomPaint(
        painter: _ScannerOverlayPainter(),
      ),
    );
  }
}

extension MlKitFormatX on mlkit.BarcodeFormat {
  custom.BarcodeFormat toCustomFormat() {
    switch (this) {
      case mlkit.BarcodeFormat.aztec:
        return custom.BarcodeFormat.aztec;
      case mlkit.BarcodeFormat.code128:
        return custom.BarcodeFormat.code128;
      case mlkit.BarcodeFormat.code39:
        return custom.BarcodeFormat.code39;
      case mlkit.BarcodeFormat.code93:
        return custom.BarcodeFormat.code93;
      case mlkit.BarcodeFormat.codabar:
        return custom.BarcodeFormat.codabar;
      case mlkit.BarcodeFormat.dataMatrix:
        return custom.BarcodeFormat.dataMatrix;
      case mlkit.BarcodeFormat.ean8:
        return custom.BarcodeFormat.ean8;
      case mlkit.BarcodeFormat.ean13:
        return custom.BarcodeFormat.ean13;
      case mlkit.BarcodeFormat.itf:
        return custom.BarcodeFormat.itf;
      case mlkit.BarcodeFormat.pdf417:
        return custom.BarcodeFormat.pdf417;
      case mlkit.BarcodeFormat.qrCode:
        return custom.BarcodeFormat.qrCode;
      case mlkit.BarcodeFormat.upca:
        return custom.BarcodeFormat.upcA;
      case mlkit.BarcodeFormat.upce:
        return custom.BarcodeFormat.upcE;
      case mlkit.BarcodeFormat.all:
        return custom.BarcodeFormat.all;
      case mlkit.BarcodeFormat.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}


class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw corners
    final cornerLength = 20.0;

    // Top left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Extension methods for format conversion
// Extension methods for format conversion
extension on custom.BarcodeFormat {
  custom.BarcodeFormat toMlKitFormat() {
    switch (this) {
      case custom.BarcodeFormat.aztec:
        return custom.BarcodeFormat.aztec;
      case custom.BarcodeFormat.code128:
        return custom.BarcodeFormat.code128;
      case custom.BarcodeFormat.code39:
        return custom.BarcodeFormat.code39;
      case custom.BarcodeFormat.code93:
        return custom.BarcodeFormat.code93;
      case custom.BarcodeFormat.codabar:
        return custom.BarcodeFormat.codabar;
      case custom.BarcodeFormat.dataMatrix:
        return custom.BarcodeFormat.dataMatrix;
      case custom.BarcodeFormat.ean8:
        return custom.BarcodeFormat.ean8;
      case custom.BarcodeFormat.ean13:
        return custom.BarcodeFormat.ean13;
      case custom.BarcodeFormat.itf:
        return custom.BarcodeFormat.itf;
      case custom.BarcodeFormat.pdf417:
        return custom.BarcodeFormat.pdf417;
      case custom.BarcodeFormat.qrCode:
        return custom.BarcodeFormat.qrCode;
      case custom.BarcodeFormat.upcA:
        return custom.BarcodeFormat.upcA;
      case custom.BarcodeFormat.upcE:
        return custom.BarcodeFormat.upcE;
      case custom.BarcodeFormat.all:
        return custom.BarcodeFormat.all;
    }
  }
}

