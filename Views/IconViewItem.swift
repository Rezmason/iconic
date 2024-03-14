//
//  IconViewItem.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/13/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

private let iconViewRect = NSRect(x: 0, y: 0, width: 128, height: 128)

class IconViewItem: NSCollectionViewItem {

  var spinner: NSProgressIndicator?
  var iconView: IconImageView?

  var icon: Icon? {
    didSet {
      iconView?.icon = icon
      if icon == nil {
        spinner?.startAnimation(nil)
      } else {
        spinner?.stopAnimation(nil)
      }
    }
  }

  override func loadView() {
    let iconImageView = self.iconView ?? IconImageView(frame: iconViewRect)
    iconImageView.autoresizingMask = [.width, .height]
    iconImageView.icon = icon
    self.iconView = iconImageView

    let spinner = self.spinner ?? NSProgressIndicator(frame: iconViewRect.insetBy(dx: 16, dy: 16))
    spinner.style = .spinning
    if #available(macOS 11.0, *) {
      spinner.controlSize = .large
    } else {
      spinner.controlSize = .regular
    }
    spinner.isDisplayedWhenStopped = false
    spinner.isIndeterminate = true
    spinner.autoresizingMask = [.width, .height]
    self.spinner = spinner
    spinner.usesThreadedAnimation = true
    if icon == nil {
      spinner.startAnimation(nil)
    }

    let view = NSView(frame: iconViewRect)
    view.addSubview(iconImageView)
    view.addSubview(spinner)
    view.autoresizesSubviews = true
    self.view = view
  }

  deinit {
    self.iconView?.icon = nil
  }
}
