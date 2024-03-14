//
//  IconImageView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/9/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class IconImageView: NSView {

  var icon: Icon? {
    didSet {
      self.setNeedsDisplay(self.bounds)
    }
  }

  override func draw(_ dirtyRect: CGRect) {
    super.draw(dirtyRect)
    guard let icon = icon else { return }
    guard let context = NSGraphicsContext.current else { return }
    context.imageInterpolation = icon.pixelated ? .none : .default
    context.shouldAntialias = !icon.pixelated
    let shortestSide = min(bounds.width, bounds.height)
    icon.image.draw(
      in: NSRect(
        x: (bounds.width - shortestSide) / 2,
        y: (bounds.height - shortestSide) / 2,
        width: shortestSide,
        height: shortestSide
      ))
  }
}
