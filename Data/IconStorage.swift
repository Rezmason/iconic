//
//  IconStorage.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

private let blockedHashes: Set = [
  "rXdYV7xLCzjuoLeCB3SL/SLtzPA=",  // kernel extension
  "HUZBJBeXkGlancanpWla5PNreladrUyy61p0mp/ZLT+05FjsbOwjRoY44TDbtbweZIPtXnz3",  // generic app
]

extension NSImage {
  fileprivate func getHash() -> String? {

    let hashRect = NSRect(x: 0, y: 0, width: 16, height: 16)
    guard let rep = bestRepresentation(for: hashRect, context: nil, hints: nil) else {
      return nil
    }

    let bitmapImageRep =
      rep as? NSBitmapImageRep
      ?? NSBitmapImageRep(
        cgImage: rep.cgImage(forProposedRect: nil, context: nil, hints: nil)!
      )
    guard
      let bytes = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 1])
    else {
      return nil
    }

    let headerSize = 768  // Apparently
    let dataSize = bytes.count - headerSize

    return bytes.subdata(in: headerSize..<(headerSize + dataSize / 8)).base64EncodedString()
  }
}

actor IconStorage<Key: Hashable> {

  typealias IconLoader = (Key) async -> Icon?

  private enum IconStorageError: Error { case cancelled }

  private enum Status {
    case unresolved
    case invalid
    case valid(icon: Icon)
  }

  private var contents = [Key: Status]()
  private var invalidCount = 0
  private var hashes = blockedHashes
  private var awaiters = [CheckedContinuation<Void, Error>]()
  private var bag = Bag<Key>()
  private let loader: IconLoader

  init(with loader: @escaping IconLoader) { self.loader = loader }

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
    if contents[key] != nil { return }
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
  }

  final func icon() async -> Icon? {
    repeat {
      if invalidCount == contents.count {
        guard
          (try? await withCheckedThrowingContinuation({ awaiters.append($0) })) != nil
        else { return nil }
      }
      if bag.isEmpty {
        bag.refill(
          from: contents.filter { (_, value) in
            if case .invalid = value { return false }
            return true
          }.keys
        )
      }
      guard let key = bag.pop(), let status = contents[key] else { continue }
      switch status {
      case .unresolved:
        guard
          let icon = await loader(key),
          let hash = icon.image.getHash(),
          !hashes.contains(hash)
        else {
          contents[key] = .invalid
          invalidCount += 1
          continue
        }
        hashes.insert(hash)
        contents[key] = .valid(icon: icon)
        return icon
      case .invalid:
        continue
      case .valid(let icon):
        return icon
      }
    } while true
  }
}
