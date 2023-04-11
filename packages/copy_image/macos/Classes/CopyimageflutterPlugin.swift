import Cocoa
import FlutterMacOS

public class CopyimageflutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "copyimageflutter", binaryMessenger: registrar.messenger)
    let instance = CopyimageflutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("Call Recieved");
        print(call.method);
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "copyImage": 
       print("Copying Image to clipboard");
        let arguments = call.arguments as! [String: Any]
        let imageData = arguments["image"] as! String
        //let image = NSImage(data: Data(base64Encoded: imageData)!)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData( Data(base64Encoded: imageData)!, forType: NSPasteboard.PasteboardType(rawValue: "NSTIFFPboardType"))
        result("image copied success")  
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// public class SharedPreferencesPlugin: NSObject, FlutterPlugin {
//   public static func register(with registrar: FlutterPluginRegistrar) {
//     let channel = FlutterMethodChannel(
//       name: "shared_preferences_macos",
//       binaryMessenger: registrar.messenger)
//     let instance = SharedPreferencesPlugin()
//     registrar.addMethodCallDelegate(instance, channel: channel)
      
    
//   }

//   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//       print("Method called");
//     switch call.method {
//     case "copyImage":
//         print("Copying Image to clipboard");
//         let arguments = call.arguments as! [String: Any]
//         let imageData = arguments["image"] as! String
//         //let image = NSImage(data: Data(base64Encoded: imageData)!)
//         let pb = NSPasteboard.general
//         pb.clearContents()
//         pb.setData( Data(base64Encoded: imageData)!, forType: NSPasteboard.PasteboardType(rawValue: "NSTIFFPboardType"))
//         result("image copied success")
// //        pb.writeObjects( [imageData])

//     // case "setBool",
//     //      "setInt",
//     //      "setDouble",
//     //      "setString",
//     //      "setStringList":
//     //   let arguments = call.arguments as! [String: Any]
//     //   let key = arguments["key"] as! String
//     //   UserDefaults.standard.set(arguments["value"], forKey: key)
//     //   result(true)
    
//     default:
//       result(FlutterMethodNotImplemented)
//     }
//   }
// }