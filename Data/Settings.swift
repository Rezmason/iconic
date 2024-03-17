//
//  Settings.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

private func getSettingsURL() -> URL? {
  guard
    let appSupportPath = NSSearchPathForDirectoriesInDomains(
      .applicationSupportDirectory,
      .userDomainMask,
      true
    ).first
  else {
    return nil
  }

  let bundleID = Bundle(for: Settings.self).bundleIdentifier!

  return URL(fileURLWithPath: appSupportPath)
    .appendingPathComponent(bundleID)
}
private let settingsURL = getSettingsURL()

class Settings: NSObject, Codable {
  @objc dynamic var count: Double = 0.5
  @objc dynamic var lifespan = 0.4
  @objc dynamic var scale = 0.6
  @objc dynamic var ripple = 0.0
  @objc dynamic var sources: Set<String> = []

  static let defaults = Settings(sources: [sourceRunningAppsKey])

  private init(sources: Set<String>) {
    super.init()
    self.sources = sources
  }

  private init(from snapshot: Settings) {
    super.init()
    overwrite(with: snapshot)
  }

  func overwrite(with snapshot: Settings) {
    count = snapshot.count
    lifespan = snapshot.lifespan
    scale = snapshot.scale
    ripple = snapshot.ripple
    sources = snapshot.sources
  }

  func snapshot() -> Settings { return Settings(from: self) }
}

extension Set {
  mutating func toggle(_ member: Element, to included: Bool) {
    if included {
      self.insert(member)
    } else {
      self.remove(member)
    }
  }
}

extension Settings {

  static func loadFromDisk() -> Settings {
    guard
      let jsonPath = settingsURL?.appendingPathComponent("settings.json").path,
      let jsonData = FileManager.default.contents(atPath: jsonPath),
      let settings = try? JSONDecoder().decode(Settings.self, from: jsonData)
    else {
      return defaults
    }
    return settings
  }

  func saveToDisk() {
    guard
      let jsonPath = settingsURL?.appendingPathComponent("settings.json").path,
      let jsonData = try? JSONEncoder().encode(self)
    else {
      return
    }
    try? FileManager.default.createDirectory(at: settingsURL!, withIntermediateDirectories: false)
    FileManager.default.createFile(atPath: jsonPath, contents: jsonData)
  }
}
