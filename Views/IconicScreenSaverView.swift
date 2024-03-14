//
//  IconicScreenSaverView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import ScreenSaver

enum BuiltInSourceKey: String, CaseIterable {
  case runningApps = "builtin_running_apps"
  case fileType = "builtin_file_type"
  case hfs = "builtin_hfs"
  case installedApps = "builtin_installed_apps"
  case systemInternals = "builtin_system_internals"
}

let includedSpritesheets = SpritesheetIconSource.loadIncluded()

private var sources = [String: IconSource]()

func getSource(for id: String) -> IconSource? {
  if let source = sources[id] {
    return source
  }

  var source: IconSource?

  switch BuiltInSourceKey.init(rawValue: id) {
  case .some(.runningApps):
    source = RunningAppsIconSource()
  case .some(.fileType):
    source = FileTypeIconSource()
  case .some(.hfs):
    source = HFSFileTypeIconSource()
  case .some(.installedApps):
    source = SpotlightIconSource.appIcons()
  case .some(.systemInternals):
    source = DeepIconSource.systemIcons()
  case .none:
    if let spritesheetDef = includedSpritesheets[id] {
      source = SpritesheetIconSource(from: spritesheetDef)
    }
  // TODO: imported sources
  }

  sources[id] = source

  return source
}

var settings = Settings.loadFromDisk()

class IconicScreenSaverView: ScreenSaverView {

  private var animation: AnimationView?
  lazy var controller = ConfigWindowController()
  var settingsObservations = [NSKeyValueObservation]()

  override func startAnimation() {
    super.startAnimation()

    let animation = AnimationView(frame: frame)
    self.animation = animation
    addSubview(animation)
    animation.start()

    settingsObservations.append(
      settings.observe(\Settings.sources, options: .initial) { settings, _ in
        guard let animation = self.animation else { return }
        animation.source = CompoundIconSource(
          of:
            settings.sources
            .intersection(
              Set(
                BuiltInSourceKey.allCases.map({ $0.rawValue }) + includedSpritesheets.keys
              )
            )
            .compactMap { getSource(for: $0) }
        )
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

  override var hasConfigureSheet: Bool {
    return true
  }

  override var configureSheet: NSWindow? {
    if controller.window == nil {
      controller.loadWindow()
    }
    return controller.window
  }
}
