enum BarcodeFormat {
  all,
  aztec,
  code128,
  code39,
  code93,
  codabar,
  dataMatrix,
  ean8,
  ean13,
  itf,
  pdf417,
  qrCode,
  upcA,
  upcE,
}

enum CameraFacing {
  back,
  front,
}

class BarcodeResult {
  final String rawValue;
  final BarcodeFormat format;
  final String? displayValue;
  final DateTime scanTime;

  BarcodeResult({
    required this.rawValue,
    required this.format,
    this.displayValue,
    DateTime? scanTime,
  }) : scanTime = scanTime ?? DateTime.now();

  @override
  String toString() => 'BarcodeResult(rawValue: $rawValue, format: $format)';
}