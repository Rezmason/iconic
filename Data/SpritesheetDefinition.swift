//
//  SpritesheetDefinition.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/14/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

struct SpritesheetDefinition: Codable {
  let assetName: String
  let iconSize: UInt
  let pixelated: Bool
  let display: IconSourceDisplay
}
