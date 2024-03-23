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

  init(from definition: SpritesheetDefinition) {

    guard
      let image = Bundle(for: SpritesheetIconSource.self).image(
        forResource: NSImage.Name(definition.assetName))
    else {
      storage = IconStorage(with: { _ in return nil })
      return
    }

    let spritesheet = IconSpritesheet(
      image: image,
      iconWidth: definition.iconSize,
      pixelated: definition.pixelated
    )
    storage = IconStorage(with: { return spritesheet.icon(at: $0) })
    Task.detached {
      await self.storage.add(contentsOf: 0..<spritesheet.count)
      await self.storage.complete()
    }
  }

  func supplyIcon(notWithin iconSet: IconSet) async -> Icon? {
    return await storage.supplyIcon(notWithin: iconSet)
  }

}
