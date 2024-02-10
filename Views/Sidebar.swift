//
//  Sidebar.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

enum SidebarElement {
  case group(name: String, contents: [SidebarElement])
  case entry(
    sourceID: String, name: String, description: String, symbol: String,
    requirement: (() -> Bool)? = nil)
}

let defaultSidebar: [SidebarElement] = [
  .group(
    name: "Basic Sets",
    contents: [
      .entry(
        sourceID: sourceRunningAppsKey,
        name: "Open Apps",
        description: "The icons of all running applications with an open window.",
        symbol: "menubar.dock.rectangle"
      ),
      .entry(
        sourceID: sourceUTTypeKey,
        name: "Common Files",
        description: "Icons for many common types of documents.",
        symbol: "doc",
        requirement: {
          if #available(macOS 11, *) { return true }
          return false
        }
      ),
      .entry(
        sourceID: sourceHFSKey,
        name: "Legacy Types",
        description: "Icons older than dirt, here with us from the beginning.",
        symbol: "book.closed"
      ),
    ]),
  .group(
    name: "Deep Dives",
    contents: [
      .entry(
        sourceID: sourceInstalledAppsKey,
        name: "Installed Apps",
        description: "The icons of applications residing in your Applications folders.",
        symbol: "square.grid.3x3"
      ),
      .entry(
        sourceID: sourceSystemInternalsKey,
        name: "System Internals",
        description: "Icons deep within the OS, representing services, capabilities and devices.",
        symbol: "cpu"
      ),
    ]),
  .group(
    name: "Reliquary",
    contents: includedSpritesheetJSON.compactMap({ (key: String, data: Any) in
      guard let data = data as? [String: Any] else {
        return nil
      }
      return .entry(
        sourceID: key,
        name: data["name"] as? String ?? key,
        description: data["description"] as? String ?? "",
        symbol: data["symbol"] as? String ?? ""
      )
    }).sorted(by: { entry1, entry2 in
      guard
        case let .entry(_, name1, _, _, _) = entry1,
        case let .entry(_, name2, _, _, _) = entry2
      else {
        return false
      }
      return name1 < name2
    })
  ),
]
