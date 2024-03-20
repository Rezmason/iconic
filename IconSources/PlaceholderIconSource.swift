//
//  PlaceholderIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/9/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import SpriteKit

class PlaceholderIconSource: IconSource {

  var image: NSImage

  init(for rect: CGRect) {
    let width = rect.width
    let shape = SKShapeNode(rect: rect, cornerRadius: width / 8)

    shape.strokeColor = SKColor.systemBlue
    shape.lineWidth = Double.maximum(width / 24, 16)
    let texture = SKView().texture(from: shape)!
    texture.usesMipmaps = true
    image = NSImage(cgImage: texture.cgImage(), size: rect.size)
  }

  func supplyIcon(notWithin iconSet: IconSet) async -> Icon? {
    return Icon(image: image)
  }
}
