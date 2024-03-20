//
//  IconStorage.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

private let blockedHashes: Set<NSString> = [
  "rXdYV7xLCzjuoLeCB3SL/SLtzPA=",  // kernel extension
  "HUZBJBeXkGlancanpWla5PNreladrUyy61p0mp/ZLT+05FjsbOwjRoY44TDbtbweZIPtXnz3",  // generic app
]

actor IconStorage<Key: Hashable> {

  typealias IconLoader = (Key) async -> Icon?

  private enum IconStorageError: Error { case cancelled }

  private enum Status {
    case unresolved
    case hashed(hash: NSString)
  }

  private var cache: NSCache<NSString, Icon> = NSCache()
  private var added = Set<Key>()
  private var contents = [Key: Status]()
  private var hashes = blockedHashes
  private var awaiters = [CheckedContinuation<Void, Error>]()
  private let loader: IconLoader

  init(with loader: @escaping IconLoader) {
    cache.countLimit = 100
    self.loader = loader
  }

  final func add<S>(contentsOf newKeys: S) async where Key == S.Element, S: Sequence {
    await withTaskGroup(
      of: Void.self,
      body: { group in
        for key in newKeys {
          group.addTask { await self.add(key) }
        }
      }
    )
  }

  final func add(_ key: Key) async {
    if added.contains(key) { return }
    added.insert(key)
    contents[key] = .unresolved

    if awaiters.isEmpty { return }
    let awaiters = self.awaiters
    self.awaiters = []
    for awaiter in awaiters { awaiter.resume() }
  }

  deinit {
    let cancelled = IconStorageError.cancelled
    for awaiter in awaiters { awaiter.resume(throwing: cancelled) }
    awaiters.removeAll()
    cache.removeAllObjects()
  }

  func supplyIcon(notWithin iconSet: IconSet) async -> Icon? {

    func isExcluded(_ status: Status) -> Bool {
      if case let .hashed(hash) = status,
        iconSet.hashes.contains(hash)
      {
        return true
      }
      return false
    }

    // phase 1: try a few random keys

    for _ in 0..<(10) {
      if let (key, status) = contents.randomElement(),
        !isExcluded(status),
        let picked = await testKey(key: key)
      {
        return picked
      }
    }

    // phase 2: enumerate the available candidates and try them all in random order

    while true {
      var candidates = contents.filter({ !isExcluded($0.value) })

      while let (key, _) = candidates.randomElement() {
        candidates.removeValue(forKey: key)
        if let picked = await testKey(key: key) {
          return picked
        }
      }

      guard
        (try? await withCheckedThrowingContinuation({ awaiters.append($0) })) != nil
      else { return nil }
    }
  }

  final private func testKey(key: Key?) async -> Icon? {
    guard let key = key, let status = contents[key] else { return nil }

    switch status {
    case .unresolved:
      guard
        let icon = await loader(key),
        !hashes.contains(icon.hash)
      else {
        contents.removeValue(forKey: key)
        return nil
      }
      let hash = icon.hash
      hashes.insert(hash)
      cache.setObject(icon, forKey: hash)
      contents[key] = .hashed(hash: hash)
      return icon
    case .hashed(let hash):
      if let icon = cache.object(forKey: hash) {
        return icon
      }
      guard let icon = await loader(key) else {
        contents.removeValue(forKey: key)
        return nil
      }
      cache.setObject(icon, forKey: hash)
      return icon
    }
  }
}
