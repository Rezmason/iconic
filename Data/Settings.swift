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
private let url = getSettingsURL()

class Settings: NSObject, Codable {
  @objc dynamic var count: Double = 0.5
  @objc dynamic var lifespan = 0.4
  @objc dynamic var scale = 0.6
  @objc dynamic var ripple = 0.0
  @objc dynamic var sources = Set<String>()

  static let defaults = Settings(sources: [BuiltInSourceID.runningApps.rawValue])

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
    guard let url = url else { return defaults }
    let jsonPath = url.appendingPathComponent("settings.json").path
    guard let jsonData = FileManager.default.contents(atPath: jsonPath) else { return defaults }
    return (try? JSONDecoder().decode(Settings.self, from: jsonData)) ?? defaults
  }

  func saveToDisk() {
    guard let url = url else { return }
    let jsonPath = url.appendingPathComponent("settings.json").path
    guard let jsonData = try? JSONEncoder().encode(self) else { return }
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    FileManager.default.createFile(atPath: jsonPath, contents: jsonData)
  }
}
