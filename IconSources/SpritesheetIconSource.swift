//
//  SpritesheetIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class SpritesheetIconSource: IconSource {

  static let bundle = Bundle(for: SpritesheetIconSource.self)

  struct Definition: Codable {
    let assetName: String
    let iconSize: UInt
    let pixelated: Bool
    let display: IconSourceDisplay
  }

  private let storage: IconStorage<UInt>

  init(from definition: Definition) {

    guard
      let image = SpritesheetIconSource.bundle.image(
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
    Task.detached { await self.storage.add(contentsOf: 0..<spritesheet.count) }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }

  static func loadIncluded() -> [String: Definition] {
    guard
      let data = NSDataAsset(name: "included_spritesheets", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([String: Definition].self, from: data)
    else {
      return [:]
    }
    return json
  }

}
