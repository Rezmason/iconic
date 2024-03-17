//
//  IconSpritesheet.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

struct IconSpritesheet {
  let image: NSImage
  let numRows: UInt
  let numColumns: UInt
  let count: UInt
  let iconSize: NSSize
  let pixelated: Bool
  private(set) var iconWidth: UInt

  init(image: NSImage, iconWidth: UInt, pixelated: Bool) {
    self.image = image
    self.iconWidth = iconWidth
    self.pixelated = pixelated
    let width = CGFloat(iconWidth)
    iconSize = NSSize(width: width, height: width)

    numRows = UInt(image.size.height / width)
    numColumns = UInt(image.size.width / width)
    count = numRows * numColumns
  }

  func icon(at index: UInt) -> Icon {
    let column = CGFloat(index % numColumns)
    let row = CGFloat(index / numColumns)
    let sourceRect = CGRect(
      origin: CGPoint(x: column * iconSize.width, y: row * iconSize.height), size: iconSize)
    let destRect = CGRect(origin: .zero, size: iconSize)
    let sprite = NSImage(size: iconSize)
    sprite.lockFocus()
    image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
    sprite.unlockFocus()
    return Icon(image: sprite, pixelated: self.pixelated)
  }
}
