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

  /// Writes decoded image bytes onto the general pasteboard as a real NSImage
  /// (TIFF) plus the original PNG/JPEG so paste can round-trip the bitmap.
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

    if isPng(rawData) {
      pb.setData(rawData, forType: .png)
    } else if isJpeg(rawData) {
      pb.setData(rawData, forType: jpegPasteboardType)
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
  /// icon (the generic "JPEG" document graphic). Those files must be read via
  /// the host app's `com.apple.security.files.user-selected.read-only`
  /// entitlement; there is no separate clipboard permission. In-memory images
  /// (Preview, Safari, screenshots) do not need that entitlement.
  private func clipboardImageResult() -> ClipboardResult {
    let pb = NSPasteboard.general
    let urls = fileURLs(from: pb)

    if !urls.isEmpty {
      for url in urls {
        if let data = readImageFile(url) {
          return .bytes(data)
        }
      }
      // Do not fall through to in-memory PNG/TIFF: for Finder copies that is
      // almost always the file icon, not the photo.
      return .fileUnreadable
    }

    for type in [NSPasteboard.PasteboardType.png, jpegPasteboardType] {
      if let data = pb.data(forType: type), isPng(data) || isJpeg(data) {
        return .bytes(data)
      }
    }

    for type in imagePasteboardTypes {
      if let data = pb.data(forType: type), let png = pngData(from: data) {
        return .bytes(png)
      }
    }

    if pb.canReadObject(forClasses: [NSImage.self], options: nil),
       let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
      for image in images where !isLikelyFileIcon(image) {
        if let png = pngData(from: image) {
          return .bytes(png)
        }
      }
    }

    return .unavailable
  }

  private func fileURLs(from pb: NSPasteboard) -> [URL] {
    var urls: [URL] = []

    let imageFiles: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
      .urlReadingContentsConformToTypes: ["public.image"],
    ]
    let anyFiles: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
    ]

    for options in [imageFiles, anyFiles] {
      if pb.canReadObject(forClasses: [NSURL.self], options: options),
         let found = pb.readObjects(forClasses: [NSURL.self], options: options) as? [URL] {
        urls.append(contentsOf: found.filter { isImageFile($0) || options[.urlReadingContentsConformToTypes] != nil })
      }
      if !urls.isEmpty {
        break
      }
    }

    if urls.isEmpty {
      for item in pb.pasteboardItems ?? [] {
        if let raw = item.string(forType: .fileURL) {
          let cleaned = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\0", with: "")
          if let url = URL(string: cleaned), url.isFileURL, isImageFile(url) {
            urls.append(url)
          }
        }
      }
    }

    if urls.isEmpty,
       let filenames = pb.propertyList(
        forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")
       ) as? [String] {
      urls.append(contentsOf: filenames.map { URL(fileURLWithPath: $0) }.filter(isImageFile))
    }

    return urls
  }

  private func isImageFile(_ url: URL) -> Bool {
    let ext = url.pathExtension.lowercased()
    return [
      "png", "jpg", "jpeg", "gif", "webp", "heic", "heif", "tif", "tiff", "bmp",
    ].contains(ext)
  }

  private func readImageFile(_ url: URL) -> Data? {
    guard let data = readFileData(url) else { return nil }
    if isPng(data) || isJpeg(data) {
      return data
    }
    return pngData(from: data)
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
    if fileData != nil {
      return fileData
    }
    return try? Data(contentsOf: url)
  }

  private var jpegPasteboardType: NSPasteboard.PasteboardType {
    NSPasteboard.PasteboardType("public.jpeg")
  }

  private var imagePasteboardTypes: [NSPasteboard.PasteboardType] {
    [
      .png,
      .tiff,
      jpegPasteboardType,
      NSPasteboard.PasteboardType("public.heic"),
    ]
  }

  private func pngData(from data: Data) -> Data? {
    if isPng(data) {
      return data
    }
    if let rep = NSBitmapImageRep(data: data),
       let png = rep.representation(using: .png, properties: [:]) {
      return png
    }
    guard let image = NSImage(data: data), !isLikelyFileIcon(image) else {
      return nil
    }
    return pngData(from: image)
  }

  private func pngData(from image: NSImage) -> Data? {
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

  private func isPng(_ data: Data) -> Bool {
    data.count >= 8 && data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
  }

  private func isJpeg(_ data: Data) -> Bool {
    data.count >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF
  }
}
