//
//  Bag.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

class Bag<T> {

  var contents = [T]()
  var isEmpty: Bool { contents.isEmpty }

  init() {

  }

  func refill<S>(from sequence: S) where T == S.Element, S: Sequence {
    contents.append(contentsOf: sequence.shuffled())
  }

  func pop() -> T? {
    return contents.popLast()
  }
}
