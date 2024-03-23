//
//  HFSFileTypeIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

class HFSFileTypeIconSource: IconSource {

  struct HFSCode: Codable {
    let fourcc: String
    let include: Bool
  }

  private let storage: IconStorage<String>

  init() {
    storage = IconStorage(with: { return Icon(image: NSWorkspace.shared.icon(forFileType: $0)) })

    Task.detached {
      await self.storage.add(
        contentsOf: Array(HFSFileTypeIconSource.loadHFSCodes().values).map({ group in
          Array(group.values).compactMap({ code in
            code.include
              ? NSFileTypeForHFSTypeCode(
                OSType(
                  code.fourcc.data(using: .macOSRoman)?
                    .reduce(0, { $0 << 8 + UInt32($1) })
                    ?? 0
                )
              )
              : nil
          })
        }).reduce([], +))
      await self.storage.complete()
    }
  }

  func supplyIcon(notWithin iconSet: IconSet) async -> Icon? {
    return await storage.supplyIcon(notWithin: iconSet)
  }

  private static func loadHFSCodes() -> [String: [String: HFSCode]] {
    let bundle = Bundle(for: HFSFileTypeIconSource.self)
    guard
      let data = NSDataAsset(name: "hfs_codes", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([String: [String: HFSCode]].self, from: data)
    else {
      return [:]
    }
    return json
  }
}
