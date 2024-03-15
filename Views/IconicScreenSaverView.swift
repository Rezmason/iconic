//
//  IconicScreenSaverView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import ScreenSaver

class IconicScreenSaverView: ScreenSaverView {

  private var animation: AnimationView?
  lazy var configSheet = ConfigWindowController(factory: factory, settings: settings)
  var settingsObservations = [NSKeyValueObservation]()
  let factory = IconFactory()
  var settings = Settings.loadFromDisk()

  override func startAnimation() {
    super.startAnimation()

    let animation = AnimationView(frame: frame, settings: settings)
    self.animation = animation
    addSubview(animation)
    animation.start()

    settingsObservations.append(
      settings.observe(\Settings.sources, options: .initial) { settings, _ in
        guard let animation = self.animation else { return }
        animation.source = self.factory.compound(of: settings.sources)
      }
    )
  }

  deinit {
    settingsObservations.removeAll()
  }

  override func stopAnimation() {
    super.stopAnimation()
    guard let animation = animation else {
      return
    }

    animation.stop()
    animation.removeFromSuperview()
    self.animation = nil
  }

  override var hasConfigureSheet: Bool { true }

  override var configureSheet: NSWindow? {
    if configSheet.window == nil {
      configSheet.loadWindow()
    }
    return configSheet.window
  }
}
