//
//  CompoundIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

actor CompoundIconSource: IconSource {

  private var sources: [IconSource]
  init(of sources: [IconSource]) { self.sources = sources.shuffled() }

  func icon() async -> Icon? {
    let sources = sources
    return await withTaskGroup(
      of: (Int, Icon?).self,
      body: { group -> Icon? in
        for index in 0..<sources.count {
          let source = sources[index]
          group.addTask { return (index, await source.icon()) }
        }

        for await (index, icon) in group.prefix(1) where icon != nil {
          group.cancelAll()
          self.sources.append(self.sources.remove(at: index))
          return icon
        }

        return nil
      }
    )
  }

}
