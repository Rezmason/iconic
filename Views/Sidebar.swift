//
//  Sidebar.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

enum SidebarElement {
  case group(name: String, contents: [SidebarElement])
  case entry(sourceID: String, display: IconSourceDisplay)
}

let builtInSidebar: [SidebarElement] = [
  .group(
    name: "Basic Sets",
    contents: [
      .entry(
        sourceID: BuiltInSourceKey.runningApps.rawValue,
        display: IconSourceDisplay(
          name: "Open Apps",
          description: "The icons of all running applications with an open window.",
          symbol: "menubar.dock.rectangle"
        )
      ),
      .entry(
        sourceID: BuiltInSourceKey.fileType.rawValue,
        display: IconSourceDisplay(
          name: "Common Files",
          description: "Icons for many common types of documents.",
          symbol: "doc"
        )
      ),
      .entry(
        sourceID: BuiltInSourceKey.hfs.rawValue,
        display: IconSourceDisplay(
          name: "Legacy Types",
          description: "Icons older than dirt, here with us from the beginning.",
          symbol: "book.closed"
        )
      ),
    ]),
  .group(
    name: "Deep Dives",
    contents: [
      .entry(
        sourceID: BuiltInSourceKey.installedApps.rawValue,
        display: IconSourceDisplay(
          name: "Installed Apps",
          description: "The icons of applications residing in your Applications folders.",
          symbol: "square.grid.3x3"
        )
      ),
      .entry(
        sourceID: BuiltInSourceKey.systemInternals.rawValue,
        display: IconSourceDisplay(
          name: "System Internals",
          description: "Icons deep within the OS, representing services, capabilities and devices.",
          symbol: "cpu"
        )
      ),
    ]),
]
