//
//  SpotlightIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

private enum SpotlightIcon: Hashable {
  case file(atPath: String)
  case resource(atForkPath: String)
  case bundle(atPath: String)
}

private func contentTypeFormat(_ contentTypes: [String]) -> String {
  return
    contentTypes
    .map { "\(NSMetadataItemContentTypeTreeKey) like '\($0)'" }
    .joined(separator: " || ")
}

private func getIcon(forBundle bundlePath: String) -> SpotlightIcon? {
  let bundleURL = URL(fileURLWithPath: bundlePath)
  let isDirectory = try? bundleURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
  if isDirectory ?? false {

    let contentsURL = bundleURL.appendingPathComponent("Contents")

    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: contentsURL,
        includingPropertiesForKeys: []
      ),
      let plist =
        (["Info", "Info-macos"].map { name -> NSDictionary? in
          let plistURL = contentsURL.appendingPathComponent("\(name).plist")
          return contents.contains(plistURL)
            ? NSDictionary(contentsOfFile: plistURL.path)
            : nil
        }.first { $0 != nil }),
      var iconFilename = plist?["CFBundleIconFile"] as? String
    else {
      return nil
    }

    if !iconFilename.lowercased().hasSuffix(".icns") {
      iconFilename += ".icns"
    }

    let iconURL = contentsURL.appendingPathComponent("Resources/\(iconFilename)")
    let iconPath = iconURL.path
    if FileManager.default.fileExists(atPath: iconPath) {
      return .file(atPath: iconPath)
    }
  } else {
    let resourceForkPath = "\(bundlePath)/..namedfork/rsrc"
    if FileManager.default.fileExists(atPath: resourceForkPath) {
      return .resource(atForkPath: resourceForkPath)
    }
  }

  return nil
}

private func getICNS(fromResourceFork path: String) -> NSImage? {
  guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
    return nil
  }

  let icnsMagic = "icns".data(using: .macOSRoman)!
  var searchRange = 0..<data.count
  while let magicRange = data.range(of: icnsMagic, options: [], in: searchRange) {
    let sizeStart = magicRange.endIndex
    let size = data.subdata(in: sizeStart..<(sizeStart + 4)).reduce(0) { $0 << 8 + $1 }
    let endIndex = magicRange.startIndex + Int(size)
    let icnsFile = data.subdata(in: magicRange.startIndex..<endIndex)

    if let image = NSImage(data: icnsFile) {
      return image
    }

    searchRange = magicRange.endIndex..<data.count
  }

  return nil
}

class SpotlightIconSource: IconSource {

  private let storage: IconStorage<SpotlightIcon>
  private let query: NSMetadataQuery
  private var token: NSObjectProtocol?

  private init(
    paths: [FileManager.SearchPathDirectory],
    domainMask: FileManager.SearchPathDomainMask,
    predicate: NSPredicate
  ) {
    storage = IconStorage(with: { spotlightIcon in
      var image: NSImage?
      switch spotlightIcon {
      case .file(atPath: let path):
        image = NSImage(contentsOfFile: path)
      case .resource(atForkPath: let forkPath):
        image = getICNS(fromResourceFork: forkPath)
      case .bundle(atPath: let path):
        let bundleIcon = NSWorkspace.shared.icon(forFile: path)
        let description = bundleIcon.description
        if !description.contains("unsupported") {
          image = bundleIcon
        }
      }
      guard let image = image else { return nil }
      return Icon(image: image, pixelated: image.size.width < 128)
    })

    let query = NSMetadataQuery()
    self.query = query
    query.searchScopes = paths.compactMap({ FileManager.default.urls(for: $0, in: domainMask) })
    query.predicate = predicate

    token = NotificationCenter.default.addObserver(
      forName: .NSMetadataQueryDidFinishGathering,
      object: query,
      queue: nil
    ) { _ in

      NotificationCenter.default.removeObserver(self.token!)
      self.token = nil
      query.disableUpdates()
      let metadataItems = query.results.compactMap { $0 as? NSMetadataItem }

      Task.detached { await self.addIconsFromFiles(in: metadataItems) }

      query.stop()
    }

    DispatchQueue.main.async { query.start() }
  }

  deinit {
    query.stop()
    if let token = token {
      NotificationCenter.default.removeObserver(token)
      self.token = nil
    }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }

  func addIconsFromFiles(in items: [NSMetadataItem]) async {
    for item in items {
      guard let itemPath = item.value(forAttribute: "kMDItemPath") as? String else {
        continue
      }
      let id = URL(fileURLWithPath: itemPath).lastPathComponent
      if id.hasSuffix(".icns") {
        await self.storage.add(.file(atPath: itemPath))
      } else if let iconPath = getIcon(forBundle: itemPath) {
        await self.storage.add(iconPath)
      }
    }
  }

  static func systemIcons() -> SpotlightIconSource {
    return SpotlightIconSource(
      paths: [
        .coreServiceDirectory,
        .allLibrariesDirectory,
      ],
      domainMask: .systemDomainMask,
      predicate: NSPredicate(format: contentTypeFormat(["com.apple.icns", "com.apple.bundle"]))
    )
  }

  static func appIcons() -> SpotlightIconSource {
    return SpotlightIconSource(
      paths: [
        .allApplicationsDirectory
      ],
      domainMask: .localDomainMask,
      predicate: NSPredicate(format: contentTypeFormat(["com.apple.application"]))
    )
  }
}
