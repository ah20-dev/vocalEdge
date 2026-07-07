import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for microphone permissions
    let controller = window?.rootViewController as! FlutterViewController
    let permissionChannel = FlutterMethodChannel(
      name: "com.vocaledge.app/permissions",
      binaryMessenger: controller.binaryMessenger
    )
    
    permissionChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "checkMicrophonePermission":
        self?.checkMicrophonePermission(result: result)
      case "showMicrophonePermissionAlert":
        self?.showMicrophonePermissionAlert(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func checkMicrophonePermission(result: @escaping FlutterResult) {
    let status = AVAudioSession.sharedInstance().recordPermission
    
    switch status {
    case .granted:
      result(true)
    case .denied, .undetermined:
      result(false)
    @unknown default:
      result(false)
    }
  }
  
  private func showMicrophonePermissionAlert(result: @escaping FlutterResult) {
    guard let rootViewController = window?.rootViewController else {
      result(FlutterError(code: "NO_CONTROLLER", message: "Root view controller not found", details: nil))
      return
    }
    
    let alert = UIAlertController(
      title: "Microphone Access Required",
      message: "Vocal Edge needs access to your microphone to record your voice. Please enable microphone access in Settings.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
      result(false)
    })
    
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
      // CRITICAL FIX: Call result() IMMEDIATELY before opening Settings
      result(true)
      
      // Dismiss alert first to free memory
      alert.dismiss(animated: false) {
        // Then open Settings
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
      }
    })
    
    rootViewController.present(alert, animated: true, completion: nil)
  }
}
