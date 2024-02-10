//
//  IconicScreenSaverView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import ScreenSaver

enum IconSourceDefinition {

  enum SpritesheetQuery {
    case packaged(_ data: [String: Any])
    case imported(_ importID: String)
  }

  enum WorkspaceQuery {
    case runningApps
    case hfs
    case uttype
  }

  enum FilesystemQuery {
    case installedApps
    case system
  }

  case spritesheet(_ query: SpritesheetQuery)
  case workspace(_ query: WorkspaceQuery)
  case filesystem(_ query: FilesystemQuery)
}

let sourceRunningAppsKey = "source_running_apps"
let sourceUTTypeKey = "source_uttype"
let sourceHFSKey = "source_hfs"
let sourceInstalledAppsKey = "source_installed_apps"
let sourceSystemInternalsKey = "source_system_internals"

let defaultSourceDefinitions: [String: IconSourceDefinition] = [
  sourceRunningAppsKey: .workspace(.runningApps),
  sourceUTTypeKey: .workspace(.uttype),
  sourceHFSKey: .workspace(.hfs),
  sourceInstalledAppsKey: .filesystem(.installedApps),
  sourceSystemInternalsKey: .filesystem(.system),
]

let bundle = Bundle(for: IconicScreenSaverView.self)

func loadIncludedSpritesheets() -> [String: Any] {
  guard
    let data = NSDataAsset(name: "included_spritesheets", bundle: bundle)?.data,
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else {
    return [:]
  }
  return json
}

let includedSpritesheetJSON = loadIncludedSpritesheets()

func registerIncludedSpritesheets() -> [String: IconSourceDefinition] {
  var defs = [String: IconSourceDefinition]()
  for key in includedSpritesheetJSON.keys {
    if let data = includedSpritesheetJSON[key] as? [String: Any] {
      defs[key] = .spritesheet(.packaged(data))
    }
  }
  return defs
}

let spritesheetSourceDefinitions = registerIncludedSpritesheets()

var importedSourceDefinitions = [String: IconSourceDefinition]()

var sourceDefinitions =
  [:]
  .merging(defaultSourceDefinitions) { element, _ in element }
  .merging(spritesheetSourceDefinitions) { element, _ in element }
  .merging(importedSourceDefinitions) { element, _ in element }

private var sources = [String: IconSource]()

func getSource(for id: String) -> IconSource? {
  if let source = sources[id] {
    return source
  }

  var source: IconSource?

  if let sourceDef = sourceDefinitions[id] {
    switch sourceDef {
    case .spritesheet(.packaged(let data)):
      source = SpritesheetIconSource(from: data)
    case .spritesheet(.imported):
      fatalError("Unimplemented")
    case .workspace(.runningApps):
      source = RunningAppsIconSource()
    case .workspace(.hfs):
      source = HFSFileTypeIconSource()
    case .workspace(.uttype):
      if #available(macOS 11, *) {
        source = UTTypeIconSource()
      }
    case .filesystem(.installedApps):
      source = SpotlightIconSource.appIcons()
    case .filesystem(.system):
      source = DeepIconSource.systemIcons()
    }
  } else {
    fatalError("Invalid source id: \(id)")
  }

  sources[id] = source

  return source
}

let settings = Settings.load()

class IconicScreenSaverView: ScreenSaverView {

  private var animation: AnimationView?
  lazy var controller = ConfigWindowController()

  override init?(frame: CGRect, isPreview: Bool) {
    super.init(frame: frame, isPreview: false)
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
  }

  override func startAnimation() {
    super.startAnimation()

    let animation = AnimationView(frame: frame)
    self.animation = animation
    addSubview(animation)
    animation.start()

    settings.sources += self.applySettings
    settings.post()
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

  private func applySettings() {
    guard let animation = animation else { return }
    animation.source = CompoundIconSource(
      of:
        Set(sourceDefinitions.keys)
        .intersection(settings.sources)
        .compactMap { getSource(for: $0) }
    )
  }
}
