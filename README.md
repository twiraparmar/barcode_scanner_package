# Barcode Scanner Package

A custom barcode scanner package for Flutter with camera preview and ML Kit integration.

## Features

- 📱 Camera preview with customizable UI
- 🔍 Support for multiple barcode formats (QR, Code128, EAN, UPC, etc.)
- 🎯 Tap to focus and pinch to zoom
- ⚡ Real-time barcode scanning
- 🔒 Camera permission handling
- 🎨 Customizable loading and error widgets
- 📱 Cross-platform support (Android & iOS)

## Supported Barcode Formats

- QR Code
- Code 128
- Code 39
- Code 93
- Codabar
- Data Matrix
- EAN-8
- EAN-13
- ITF
- PDF417
- UPC-A
- UPC-E
- Aztec

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  barcode_scanner_package: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:barcode_scanner_package/barcode_scanner_package.dart';

BarcodeScanner(
  onScan: (BarcodeResult result) {
    print('Scanned: ${result.rawValue}');
    print('Format: ${result.format}');
  },
  onError: (Exception error) {
    print('Error: $error');
  },
)
```

### Advanced Usage

```dart
BarcodeScanner(
  formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
  cameraFacing: CameraFacing.back,
  autoFocus: true,
  enableTapToFocus: true,
  enablePinchToZoom: true,
  scanInterval: Duration(milliseconds: 500),
  loadingWidget: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
  onScan: (BarcodeResult result) {
    // Handle scan result
  },
  onError: (Exception error) {
    // Handle error
  },
)
```

### Customization Options

```dart
BarcodeScanner(
  // Scanning line customization
  scanningLineColor: Colors.blue,
  scanningLineHeight: 3.0,
  scanningLineDuration: Duration(seconds: 3),
  showScanningLine: true,
  
  // Corner brackets customization
  cornerBracketColor: Colors.blue,
  cornerBracketWidth: 4.0,
  
  // Scanning area customization
  scanningAreaSize: 300.0,
  overlayColor: Colors.black54,
  
  // Text and instructions
  scanningInstructionText: 'Custom: Position barcode here',
  showInstructions: true,
  
  onScan: (BarcodeResult result) {
    print('Scanned: ${result.rawValue}');
    print('Format: ${result.format}');
  },
)
```

### SimpleBarcodeScanner Widget

For easier integration with automatic state management:

```dart
SimpleBarcodeScanner(
  scanningLineColor: Colors.green,
  scanningAreaSize: 250.0,
  onScan: (BarcodeResult result) {
    // Automatically handles state management
    print('Scanned: ${result.rawValue}');
  },
)
```

### Check Camera Availability

```dart
// Check if camera is available
bool hasCamera = await BarcodeScanner.hasCamera;

// Request camera permission
bool hasPermission = await BarcodeScanner.requestCameraPermission();
```

## Permissions

### Android

Add camera permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

### iOS

Add camera usage description to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan barcodes</string>
```

## Example

See the `example/` directory for a complete example app.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
