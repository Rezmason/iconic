//
//  Icon.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

extension NSImage {
  fileprivate func getHash() -> NSString? {

    let hashRect = NSRect(x: 0, y: 0, width: 16, height: 16)
    guard let rep = bestRepresentation(for: hashRect, context: nil, hints: nil) else {
      return nil
    }

    let bitmapImageRep =
      rep as? NSBitmapImageRep
      ?? NSBitmapImageRep(
        cgImage: rep.cgImage(forProposedRect: nil, context: nil, hints: nil)!
      )
    guard
      let bytes = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 1])
    else {
      return nil
    }

    let headerSize = 768  // Apparently
    let dataSize = bytes.count - headerSize

    return bytes.subdata(in: headerSize..<(headerSize + dataSize / 8)).base64EncodedString()
      as NSString
  }
}

class Icon: Hashable {
  let hash: NSString
  let image: NSImage
  let pixelated: Bool

  init(image: NSImage, pixelated: Bool = false) {
    self.image = image
    hash = image.getHash() ?? ""
    self.pixelated = pixelated
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(hash)
  }

  static func == (lhs: Icon, rhs: Icon) -> Bool {
    return lhs.hash == rhs.hash
  }
}
