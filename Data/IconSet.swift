//
//  IconSet.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/19/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class IconSet {
  private(set) var hashes = Set<NSString>()

  func add(_ icon: Icon?) {
    guard let icon = icon else { return }
    hashes.insert(icon.hash)
  }

  func remove(_ icon: Icon?) {
    guard let icon = icon else { return }
    hashes.remove(icon.hash)
  }

  func removeAll() {
    hashes.removeAll()
  }
}
