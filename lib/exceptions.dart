class BarcodeScannerException implements Exception {
  final String message;
  final dynamic error;

  BarcodeScannerException(this.message, [this.error]);

  @override
  String toString() => 'BarcodeScannerException: $message${error != null ? ' - $error' : ''}';
}

class CameraPermissionDeniedException extends BarcodeScannerException {
  CameraPermissionDeniedException() : super('Camera permission denied');
}

class CameraNotAvailableException extends BarcodeScannerException {
  CameraNotAvailableException() : super('Camera not available');
}

class ScannerInitializationException extends BarcodeScannerException {
  ScannerInitializationException([dynamic error])
      : super('Failed to initialize scanner', error);
}