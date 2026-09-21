import Cocoa
import FlutterMacOS

public class CopyPasteMediaPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "copy_paste_media", binaryMessenger: registrar.messenger)
    let instance = CopyPasteMediaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "copyImage":
      copyImage(call, result: result)
    case "pasteImage":
      pasteImage(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func copyImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String: Any]
    let imageData = arguments["image"] as! String
    let pb = NSPasteboard.general
    pb.clearContents()
    if let data = Data(base64Encoded: imageData), let image = NSImage(data: data) {
      pb.writeObjects([image])
    }
    result("image copied success")
  }

  private func pasteImage(result: @escaping FlutterResult) {
    if let data = clipboardImageBytes() {
      result(FlutterStandardTypedData(bytes: data))
    } else {
      result(nil)
    }
  }

  /// Finder file copies include a file URL plus a file-type icon. Read the
  /// file first (needs `com.apple.security.files.user-selected.read-only`).
  /// Preview / Safari / screenshots only need the in-memory NSImage.
  private func clipboardImageBytes() -> Data? {
    let pb = NSPasteboard.general
    let urls = fileURLs(from: pb)

    if !urls.isEmpty {
      for url in urls {
        if let data = readFileData(url) {
          return data
        }
      }
      return nil
    }

    if pb.canReadObject(forClasses: [NSImage.self], options: nil),
       let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
       let image = images.first,
       let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff) {
      return rep.representation(using: .png, properties: [:])
    }

    return nil
  }

  private func fileURLs(from pb: NSPasteboard) -> [URL] {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
      .urlReadingContentsConformToTypes: ["public.image"],
    ]
    if pb.canReadObject(forClasses: [NSURL.self], options: options),
       let urls = pb.readObjects(forClasses: [NSURL.self], options: options) as? [URL] {
      return urls
    }
    return []
  }

  private func readFileData(_ url: URL) -> Data? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        url.stopAccessingSecurityScopedResource()
      }
    }
    return try? Data(contentsOf: url)
  }
}
