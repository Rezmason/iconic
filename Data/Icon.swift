//
//  Icon.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa
import CryptoKit

private let hashRect = NSRect(x: 0, y: 0, width: 16, height: 16)
private let hashImage = NSImage(size: hashRect.size)

extension NSImage {

  fileprivate func getHash() -> NSString? {

    hashImage.lockFocus()
    NSColor.gray.setFill()
    hashRect.fill()
    NSGraphicsContext.current?.shouldAntialias = false
    NSGraphicsContext.current?.imageInterpolation = .none
    self.draw(in: hashRect)
    hashImage.unlockFocus()

    guard let cgImage = hashImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let bytes = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1])
    else { return nil }

    let hashed = Insecure.MD5.hash(data: bytes).map({ String(format: "%02hhX", $0) }).joined()
    return hashed as NSString
  }
}

class Icon: Hashable {
  let hash: NSString
  let image: NSImage
  let pixelated: Bool

  init(image: NSImage, pixelated: Bool = false) {
    self.image = image
    hash = image.getHash() ?? String(Int.random(in: 0..<Int.max)) as NSString
    self.pixelated = pixelated
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(hash)
  }

  static func == (lhs: Icon, rhs: Icon) -> Bool {
    return lhs.hash == rhs.hash
  }
}
