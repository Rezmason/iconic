//
//  DeepIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import SpriteKit

class DeepIconSource: IconSource {

  private let storage: IconStorage<String>
  private let search: Process
  private let minWidth: CGFloat
  private let minEntropy: CGFloat

  private init(
    withMinWidth minWidth: CGFloat,
    withMinEntropy minEntropy: CGFloat,
    findArgs: [String]
  ) {
    search = Process()
    self.minWidth = minWidth
    self.minEntropy = minEntropy

    storage = IconStorage(with: { file in

      // Late validation of width, size and entropy— memory/time tradeoff

      guard
        let image = NSImage(contentsOfFile: file),
        image.size.width >= minWidth
      else {
        return nil
      }

      if file.contains("com.apple.") { return Icon(image: image) }

      guard
        let attributes = try? FileManager.default.attributesOfItem(atPath: file),
        let size = attributes[FileAttributeKey.size] as? Float
      else {
        return nil
      }

      let largestRepWidth = image.representations.map { $0.size.width }.max()!
      let entropy = CGFloat(size) / pow(largestRepWidth, 2)
      return entropy < minEntropy
        ? nil
        : Icon(image: image)
    })

    beginSearch(with: findArgs)
  }

  deinit {
    if search.isRunning { search.terminate() }
  }

  func beginSearch(with args: [String]) {

    search.executableURL = URL(fileURLWithPath: "/usr/bin/find")
    search.arguments = args

    let stdout = Pipe()
    search.standardOutput = stdout
    search.standardError = Pipe()  // Suppress "Permission denied" stderrs
    var feed = ""
    let fileHandle = stdout.fileHandleForReading

    func addPaths() {
      let cutoff = feed.lastIndex(of: "\n") ?? feed.indices.last!
      let lines = feed[..<cutoff].split(separator: "\n").map { String($0) }
      feed = String(feed[cutoff...])
      Task.detached { await self.storage.add(contentsOf: lines) }
    }

    fileHandle.readabilityHandler = { handle in
      let data = handle.availableData
      guard data.count > 0 else {
        fileHandle.readabilityHandler = nil
        addPaths()
        return
      }

      guard let text = String(data: data, encoding: .utf8) else {
        print("<Invalid text>")
        return
      }

      feed += text
      addPaths()
    }

    try? self.search.run()
  }

  func icon() async -> Icon? {
    await storage.icon()
  }

  static func systemIcons() -> DeepIconSource {
    return DeepIconSource(
      withMinWidth: 128,
      withMinEntropy: 0.8,
      findArgs: ["/System/Library", "-regex", #".*\.icns"#]
    )
  }
}
