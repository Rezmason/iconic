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

  enum State {
    case empty
    case pending
    case loaded(Icon)
  }

  var state: State = .empty {
    didSet { updateState() }
  }

  override func loadView() {
    let iconImageView = self.iconView ?? IconImageView(frame: iconViewRect)
    iconImageView.autoresizingMask = [.width, .height]
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

    let view = NSView(frame: iconViewRect)
    view.addSubview(iconImageView)
    view.addSubview(spinner)
    view.autoresizesSubviews = true
    self.view = view

    updateState()
  }

  private func updateState() {
    let icon: Icon?
    let spinning: Bool

    switch state {
    case .empty:
      icon = nil
      spinning = false
    case .pending:
      icon = nil
      spinning = true
    case .loaded(let loadedIcon):
      icon = loadedIcon
      spinning = false
    }

    iconView?.icon = icon

    if spinning {
      spinner?.startAnimation(nil)
    } else {
      spinner?.stopAnimation(nil)
    }
  }

  deinit {
    self.state = .empty
    self.iconView?.icon = nil
  }
}
