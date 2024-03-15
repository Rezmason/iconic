//
//  IconFactory.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/14/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class IconFactory {

  let includedSpritesheets = IconFactory.loadIncludedSpritesheets()
  private var sources = [String: IconSource]()

  func source(for id: String) -> IconSource? {
    if let source = sources[id] {
      return source
    }

    var source: IconSource?

    switch BuiltInSourceID.init(rawValue: id) {
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

  func compound(of sourceIDs: Set<String>) -> CompoundIconSource {
    return CompoundIconSource(
      of:
        sourceIDs
        .intersection(
          Set(
            BuiltInSourceID.allCases.map({ $0.rawValue }) + includedSpritesheets.keys
          )
        )
        .compactMap { source(for: $0) }
    )
  }

  static func loadIncludedSpritesheets() -> [String: SpritesheetDefinition] {
    let bundle = Bundle(for: IconFactory.self)
    guard
      let data = NSDataAsset(name: "included_spritesheets", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([String: SpritesheetDefinition].self, from: data)
    else {
      return [:]
    }
    return json
  }
}
