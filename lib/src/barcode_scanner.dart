import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

import 'barcode_types.dart';
import '../exceptions.dart';

class BarcodeScanner extends StatefulWidget {
  final List<BarcodeFormat> formats;
  final CameraFacing cameraFacing;
  final bool autoFocus;
  final bool enableTapToFocus;
  final bool enablePinchToZoom;
  final Duration scanInterval;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final BoxFit fit;
  final Function(BarcodeResult)? onScan;
  final Function(Exception)? onError;

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

  const BarcodeScanner({
    super.key,
    this.formats = const [BarcodeFormat.all],
    this.cameraFacing = CameraFacing.back,
    this.autoFocus = true,
    this.enableTapToFocus = true,
    this.enablePinchToZoom = true,
    this.scanInterval = const Duration(milliseconds: 1000),
    this.loadingWidget,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.onScan,
    this.onError,

    // Customization defaults
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
  State<BarcodeScanner> createState() => _BarcodeScannerState();

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

class _BarcodeScannerState extends State<BarcodeScanner>
    with TickerProviderStateMixin {
  CameraController? _controller;
  late mlkit.BarcodeScanner _barcodeScanner;
  bool _isInitialized = false;
  bool _hasError = false;
  double _zoomLevel = 1.0;
  Timer? _scanTimer;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: widget.scanningLineDuration,
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));
    if (widget.showScanningLine) {
      _scanAnimationController.repeat(reverse: true);
    }
    _initializeScanner();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _barcodeScanner.close();
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      // Check camera permission
      if (!await BarcodeScanner.requestCameraPermission()) {
        throw CameraPermissionDeniedException();
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraNotAvailableException();
      }

      // Select camera based on facing
      final camera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (widget.cameraFacing == CameraFacing.back
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
      final formats = widget.formats
          .map((f) => f.toMlKitFormat())
          .toList()
          .cast<mlkit.BarcodeFormat>();

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
        e is BarcodeScannerException ? e : ScannerInitializationException(e),
      );
    }
  }

  void _startScanning() {
    _scanTimer = Timer.periodic(widget.scanInterval, (timer) async {
      if (_controller == null || !_controller!.value.isInitialized) return;

      try {
        // Check if camera is ready and not busy
        if (_controller!.value.isTakingPicture) return;

        final image = await _controller!.takePicture();
        final inputImage = mlkit.InputImage.fromFilePath(image.path);
        final barcodes = await _barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first;
          if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
            final result = BarcodeResult(
              rawValue: barcode.rawValue!,
              format: barcode.format.toCustomFormat(),
              displayValue: barcode.displayValue,
            );

            widget.onScan?.call(result);
          }
        }

        // Clean up the image file
        try {
          await File(image.path).delete();
        } catch (e) {
          // Ignore file deletion errors
        }
      } catch (e) {
        // Filter out common camera busy errors
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('camera') ||
            !errorMessage.contains('busy') ||
            !errorMessage.contains('exception')) {
          widget.onError?.call(BarcodeScannerException('Scan failed', e));
        }
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
    return Stack(
      children: [
        // Semi-transparent overlay
        Container(
          color: widget.overlayColor.withOpacity(0.5),
        ),
        // Scanning area
        Center(
          child: Container(
            width: widget.scanningAreaSize,
            height: widget.scanningAreaSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Animated scanning line
                if (widget.showScanningLine) _buildScanningLine(),
                // Corner brackets
                _buildCornerBrackets(),
                // Scanning text
                _buildScanningText(),
              ],
            ),
          ),
        ),
        // Instructions
        if (widget.showInstructions) _buildInstructions(),
      ],
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        
        return Positioned(
          top: _scanAnimation.value * widget.scanningAreaSize,
          left: 0,
          right: 0,
          child: Container(
            height: widget.scanningLineHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  widget.scanningLineColor,
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerBrackets() {
    return Stack(
      children: [
        // Top left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
                left: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
              ),
            ),
          ),
        ),
        // Top right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
                right: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
              ),
            ),
          ),
        ),
        // Bottom left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
                left: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
              ),
            ),
          ),
        ),
        // Bottom right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
                right: BorderSide(
                    color: widget.cornerBracketColor,
                    width: widget.cornerBracketWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningText() {
    return Positioned(
      bottom: -40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          widget.scanningInstructionText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Point your camera at a barcode or QR code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInstructionItem(Icons.touch_app, 'Tap to focus'),
              _buildInstructionItem(Icons.zoom_in, 'Pinch to zoom'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

extension MlKitFormatX on mlkit.BarcodeFormat {
  BarcodeFormat toCustomFormat() {
    switch (this) {
      case mlkit.BarcodeFormat.aztec:
        return BarcodeFormat.aztec;
      case mlkit.BarcodeFormat.code128:
        return BarcodeFormat.code128;
      case mlkit.BarcodeFormat.code39:
        return BarcodeFormat.code39;
      case mlkit.BarcodeFormat.code93:
        return BarcodeFormat.code93;
      case mlkit.BarcodeFormat.codabar:
        return BarcodeFormat.codabar;
      case mlkit.BarcodeFormat.dataMatrix:
        return BarcodeFormat.dataMatrix;
      case mlkit.BarcodeFormat.ean8:
        return BarcodeFormat.ean8;
      case mlkit.BarcodeFormat.ean13:
        return BarcodeFormat.ean13;
      case mlkit.BarcodeFormat.itf:
        return BarcodeFormat.itf;
      case mlkit.BarcodeFormat.pdf417:
        return BarcodeFormat.pdf417;
      case mlkit.BarcodeFormat.qrCode:
        return BarcodeFormat.qrCode;
      case mlkit.BarcodeFormat.upca:
        return BarcodeFormat.upcA;
      case mlkit.BarcodeFormat.upce:
        return BarcodeFormat.upcE;
      case mlkit.BarcodeFormat.all:
        return BarcodeFormat.all;
      case mlkit.BarcodeFormat.unknown:
        return BarcodeFormat.all;
    }
  }
}

// Extension methods for format conversion
extension BarcodeFormatX on BarcodeFormat {
  mlkit.BarcodeFormat toMlKitFormat() {
    switch (this) {
      case BarcodeFormat.aztec:
        return mlkit.BarcodeFormat.aztec;
      case BarcodeFormat.code128:
        return mlkit.BarcodeFormat.code128;
      case BarcodeFormat.code39:
        return mlkit.BarcodeFormat.code39;
      case BarcodeFormat.code93:
        return mlkit.BarcodeFormat.code93;
      case BarcodeFormat.codabar:
        return mlkit.BarcodeFormat.codabar;
      case BarcodeFormat.dataMatrix:
        return mlkit.BarcodeFormat.dataMatrix;
      case BarcodeFormat.ean8:
        return mlkit.BarcodeFormat.ean8;
      case BarcodeFormat.ean13:
        return mlkit.BarcodeFormat.ean13;
      case BarcodeFormat.itf:
        return mlkit.BarcodeFormat.itf;
      case BarcodeFormat.pdf417:
        return mlkit.BarcodeFormat.pdf417;
      case BarcodeFormat.qrCode:
        return mlkit.BarcodeFormat.qrCode;
      case BarcodeFormat.upcA:
        return mlkit.BarcodeFormat.upca;
      case BarcodeFormat.upcE:
        return mlkit.BarcodeFormat.upce;
      case BarcodeFormat.all:
        return mlkit.BarcodeFormat.all;
    }
  }
}
