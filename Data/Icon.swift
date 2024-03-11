//
//  Icon.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class Icon: NSObject {
  let image: NSImage
  let pixelated: Bool

  init(image: NSImage, pixelated: Bool = false) {
    self.image = image
    self.pixelated = pixelated
  }
}
