import Flutter
import UIKit

public class BarcodeScannerFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "barcode_scanner_package", binaryMessenger: registrar.messenger())
    let instance = BarcodeScannerFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "hasCamera":
      let hasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
      result(hasCamera)
    case "requestCameraPermission":
      // This should be handled by the permission_handler plugin
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
