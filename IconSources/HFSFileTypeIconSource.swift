//
//  HFSFileTypeIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

extension String {
  fileprivate var fourCharCodeValue: OSType {
    var result = 0
    if let data = self.data(using: String.Encoding.macOSRoman) {
      data.withUnsafeBytes({ rawBytes in
        let bytes = rawBytes.bindMemory(to: UInt8.self)
        for index in 0..<data.count {
          result = result << 8 + Int(bytes[index])
        }
      })
    }
    return OSType(result)
  }
}

class HFSFileTypeIconSource: IconSource {

  struct HFSCode: Codable {
    let fourcc: String
    let include: Bool
  }

  static let bundle = Bundle(for: HFSFileTypeIconSource.self)

  private let storage: IconStorage<String>

  init() {
    storage = IconStorage(with: { return Icon(image: NSWorkspace.shared.icon(forFileType: $0)) })

    Task.detached {
      await self.storage.add(
        contentsOf: Array(HFSFileTypeIconSource.loadHFSCodes().values).map({ group in
          Array(group.values).compactMap({ code in
            code.include ? NSFileTypeForHFSTypeCode(code.fourcc.fourCharCodeValue) : nil
          })
        }).reduce([], +))
    }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }

  private static func loadHFSCodes() -> [String: [String: HFSCode]] {
    guard
      let data = NSDataAsset(name: "hfs_codes", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([String: [String: HFSCode]].self, from: data)
    else {
      return [:]
    }
    return json
  }
}
