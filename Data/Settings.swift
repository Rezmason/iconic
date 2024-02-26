//
//  Config.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

// import Foundation
// import AppKit
import ScreenSaver

let bundleID = Bundle(for: Settings.self).bundleIdentifier!
private var screensaverDefaults = ScreenSaverDefaults(forModuleWithName: bundleID)

func getSettingsURL() -> URL? {
  guard
    let appSupportPath = NSSearchPathForDirectoriesInDomains(
      .applicationSupportDirectory,
      .userDomainMask,
      true
    ).first
  else {
    return nil
  }

  return URL(fileURLWithPath: appSupportPath)
    .appendingPathComponent(bundleID)
}

let settingsURL = getSettingsURL()

class Observable<T> {
  typealias Observer = (T) -> Void
  private var observers = [(T) -> Void]()
  func clearObservers() { observers.removeAll() }

  deinit { clearObservers() }

  func post(_ value: T) {
    for observer in observers {
      observer(value)
    }
  }

  static func += (param: Observable<T>, observer: @escaping Observer) {
    param.observers.append(observer)
  }
}

class Param<T>: Observable<T> {
  var value: T { didSet { post(value) } }
  init(_ value: T) { self.value = value }
  func post() { post(value) }
}

class SetParam<T: Hashable>: Observable<()>, Sequence {
  private var elements = Set<T>()

  init(_ elements: [T]?) {
    if let elements = elements {
      self.elements.formUnion(elements)
    }
  }

  func contains(_ element: T) -> Bool { elements.contains(element) }

  func insert(_ element: T) {
    if elements.insert(element).inserted {
      post(())
    }
  }

  func remove(_ element: T) {
    if elements.remove(element) != nil {
      post(())
    }
  }

  func clear() {
    if elements.count > 0 {
      elements.removeAll()
      post(())
    }
  }

  func overwrite(_ other: SetParam<T>) {
    elements.removeAll()
    elements.formUnion(other.elements)
    post(())
  }

  func toggle(_ element: T, to include: Bool) {
    if include {
      insert(element)
    } else {
      remove(element)
    }
  }

  func makeIterator() -> Set<T>.Iterator { self.elements.makeIterator() }

  func post() { post(()) }
}

class Settings {

  static let defaults = Settings { settings in
    settings.count.value = 0.5
    settings.lifespan.value = 0.4
    settings.scale.value = 0.6
    settings.aqua.value = 0.0
    settings.sources.insert(sourceRunningAppsKey)
  }

  let count = Param(0.0)
  let lifespan = Param(0.0)
  let scale = Param(0.0)
  let aqua = Param(0.0)
  let sources = SetParam<String>([])

  static func load() -> Settings {
    var dict: [String: Any]?
    if let jsonPath = settingsURL?.appendingPathComponent("settings.json").path,
      let jsonData = FileManager.default.contents(atPath: jsonPath),
      let jsonObject = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
    {
      dict = jsonObject
      //      backgroundColor = .green
    } else if let screensaverDefaults = screensaverDefaults {
      dict = screensaverDefaults.dictionaryRepresentation()
      //      backgroundColor = .red
    }
    guard let dict = dict else {
      //      backgroundColor = .blue
      return Settings(from: .defaults)
    }

    return Settings { settings in
      if let sources = dict["sources"] as? [String] {
        for source in sources {
          settings.sources.insert(source)
        }
      }
      settings.count.value = dict["count"] as? Double ?? Settings.defaults.count.value
      settings.lifespan.value = dict["lifespan"] as? Double ?? Settings.defaults.lifespan.value
      settings.scale.value = dict["scale"] as? Double ?? Settings.defaults.scale.value
      settings.aqua.value = dict["aqua"] as? Double ?? Settings.defaults.aqua.value
    }
  }

  func save() {
    let jsonObject: [String: Any] = [
      "sources": Array(sources),
      "count": count.value,
      "lifespan": lifespan.value,
      "scale": scale.value,
      "aqua": aqua.value,
    ]

    if let settingsURL = settingsURL {
      do {
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
        let jsonPath = settingsURL.appendingPathComponent("settings.json").path
        try? FileManager.default.createDirectory(
          at: settingsURL, withIntermediateDirectories: false)
        FileManager.default.createFile(atPath: jsonPath, contents: jsonData)
      }
    }

    if let screensaverDefaults = screensaverDefaults {
      screensaverDefaults.setValuesForKeys(jsonObject)
    }
  }

  private init(where initializer: (Settings) -> Void) {
    initializer(self)
  }

  private init(from snapshot: Settings) {
    overwrite(snapshot)
  }

  func snapshot() -> Settings {
    return Settings(from: self)
  }

  func post() {
    count.post()
    lifespan.post()
    scale.post()
    aqua.post()
    sources.post()
  }

  func overwrite(_ other: Settings) {
    count.value = other.count.value
    lifespan.value = other.lifespan.value
    scale.value = other.scale.value
    aqua.value = other.aqua.value
    sources.overwrite(other.sources)
  }
}
