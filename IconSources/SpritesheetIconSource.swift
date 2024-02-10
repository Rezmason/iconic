//
//  SpritesheetIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class SpritesheetIconSource: IconSource {

  private let storage: IconStorage<UInt>

  init(from spritesheetData: [String: Any]) {

    guard
      let assetName = spritesheetData["assetName"] as? String,
      let iconWidth = spritesheetData["iconSize"] as? UInt,
      let image = bundle.image(forResource: NSImage.Name(assetName))
    else {
      storage = IconStorage(with: { _ in return nil })
      return
    }

    let pixelated = spritesheetData["pixelated"] as? Bool ?? false
    let spritesheet = IconSpriteSheet(image: image, iconWidth: iconWidth, pixelated: pixelated)
    storage = IconStorage(with: { return spritesheet.icon(at: $0) })
    Task.detached { await self.storage.add(contentsOf: 0..<spritesheet.count) }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }
}
