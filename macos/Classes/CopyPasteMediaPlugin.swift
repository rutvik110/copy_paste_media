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
      switch clipboardImageResult() {
      case .bytes(let data):
        result(FlutterStandardTypedData(bytes: data))
      case .fileUnreadable:
        result(FlutterError(
          code: "file_access_denied",
          message: "Could not read the copied file. A sandboxed app needs com.apple.security.files.user-selected.read-only to paste images copied in Finder.",
          details: nil
        ))
      case .unavailable:
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Decodes the bytes as an image and writes that NSImage to the pasteboard.
  private func copyImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let imageBase64 = arguments["image"] as? String,
          let rawData = Data(base64Encoded: imageBase64) else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "Expected base64 image data",
        details: nil
      ))
      return
    }

    guard let image = NSImage(data: rawData), image.isValid else {
      result(FlutterError(
        code: "invalid_image",
        message: "Could not decode image data",
        details: nil
      ))
      return
    }

    let pb = NSPasteboard.general
    pb.clearContents()

    guard pb.writeObjects([image]) else {
      result(FlutterError(
        code: "copy_failed",
        message: "Pasteboard rejected the image",
        details: nil
      ))
      return
    }

    result("image copied success")
  }

  private enum ClipboardResult {
    case bytes(Data)
    case unavailable
    case fileUnreadable
  }

  /// Image bytes from the general pasteboard.
  ///
  /// Finder file copies put a `public.file-url` *and* a PNG of the file-type
  /// icon. Those files must be read via the host app's
  /// `com.apple.security.files.user-selected.read-only` entitlement. In-memory
  /// images (Preview, Safari, screenshots) do not need that entitlement.
  private func clipboardImageResult() -> ClipboardResult {
    let pb = NSPasteboard.general
    let urls = fileURLs(from: pb)

    if !urls.isEmpty {
      for url in urls {
        if let data = readImageFile(url) {
          return .bytes(data)
        }
      }
      // Do not fall through to in-memory types: for Finder copies that is
      // almost always the file icon, not the photo.
      return .fileUnreadable
    }

    if pb.canReadObject(forClasses: [NSImage.self], options: nil),
       let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
      for image in images where !isLikelyFileIcon(image) {
        if let data = imageBytes(from: image) {
          return .bytes(data)
        }
      }
    }

    return .unavailable
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

  private func readImageFile(_ url: URL) -> Data? {
    guard let data = readFileData(url), NSImage(data: data) != nil else {
      return nil
    }
    return data
  }

  private func readFileData(_ url: URL) -> Data? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        url.stopAccessingSecurityScopedResource()
      }
    }

    var fileData: Data?
    var coordinatorError: NSError?
    NSFileCoordinator().coordinate(
      readingItemAt: url,
      options: .withoutChanges,
      error: &coordinatorError
    ) { coordinatedURL in
      fileData = try? Data(contentsOf: coordinatedURL)
    }
    return fileData ?? (try? Data(contentsOf: url))
  }

  private func imageBytes(from image: NSImage) -> Data? {
    for case let bitmap as NSBitmapImageRep in image.representations {
      if let png = bitmap.representation(using: .png, properties: [:]) {
        return png
      }
    }
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    return rep.representation(using: .png, properties: [:])
  }

  /// Finder / NSWorkspace file icons have several standard icon sizes.
  private func isLikelyFileIcon(_ image: NSImage) -> Bool {
    let reps = image.representations
    guard reps.count >= 2 else { return false }
    let iconWidths: Set<Int> = [16, 18, 32, 36, 64, 128, 256, 512, 1024]
    let widths = Set(reps.map { $0.pixelsWide })
    return widths.count >= 2 && widths.isSubset(of: iconWidths)
  }
}
