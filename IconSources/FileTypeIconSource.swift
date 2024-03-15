//
//  FileTypeIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

class FileTypeIconSource: IconSource {

  private let storage: IconStorage<String>

  init() {
    storage = IconStorage(with: {
      if #available(macOS 11, *) {
        guard let uttype = UTType.init($0) else { return nil }
        return Icon(image: NSWorkspace.shared.icon(for: uttype))
      } else {
        return Icon(image: NSWorkspace.shared.icon(forFileType: $0))
      }
    })
    Task.detached { await self.storage.add(contentsOf: FileTypeIconSource.loadContentTypes()) }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }

  private static func loadContentTypes() -> [String] {
    let bundle = Bundle(for: FileTypeIconSource.self)
    guard
      let data = NSDataAsset(name: "file_types", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([String].self, from: data)
    else {
      return []
    }
    return json
  }
}
