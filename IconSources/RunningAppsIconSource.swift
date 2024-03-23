//
//  RunningAppsIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class RunningAppsIconSource: IconSource {

  private let storage: IconStorage<pid_t>

  init() {

    let openWindows =
      CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID) as? [[String: Any]]
    let allWindowPIDs = Set<Int>(openWindows?.compactMap({ $0["kCGWindowOwnerPID"] as? Int }) ?? [])
    let apps = Dictionary.init(
      uniqueKeysWithValues:
        NSWorkspace.shared.runningApplications
        .filter { allWindowPIDs.isEmpty || allWindowPIDs.contains(Int($0.processIdentifier)) }
        .map({ app in (app.processIdentifier, app) })
    ).compactMapValues { $0 }

    storage = IconStorage(with: {
      guard let image = apps[$0]?.icon else { return nil }
      return Icon(image: image)
    })

    Task.detached {
      await self.storage.add(contentsOf: apps.keys)
      await self.storage.complete()
    }
  }

  func supplyIcon(notWithin iconSet: IconSet) async -> Icon? {
    return await storage.supplyIcon(notWithin: iconSet)
  }
}
