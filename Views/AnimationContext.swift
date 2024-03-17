//
//  AnimationContext.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/9/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import SpriteKit

class AnimationContext {
  let maxIcons = 30
  let iconRect: CGRect

  let backScale: Double = 8
  let backRange: (x: ClosedRange<Double>, y: ClosedRange<Double>)
  let frontRange: (x: ClosedRange<Double>, y: ClosedRange<Double>)
  let focalLength: Double
  let backZ: Double
  let frontZ: Double

  var count = 0
  var lifespan = 0.0
  var scale = 0.0
  var ripple = 0.0

  var warpPoints: [vector_float2]
  let warp: SKWarpGeometryGrid

  init(for frame: NSRect) {

    let largestFrameDimension = Double(max(frame.width, frame.height))
    focalLength = largestFrameDimension
    frontZ = largestFrameDimension
    backZ = frontZ * backScale

    let width = Double(frame.width)
    let height = Double(frame.height)
    frontRange = (x: 0...width, y: 0...height)
    backRange = (x: 0...(backScale * width), y: 0...(backScale * height))

    let idealIconWidth = largestFrameDimension / 6.25
    let minIconWidth = 32.0
    let maxIconWidth = 1024.0
    let iconWidth = min(
      maxIconWidth,
      max(
        minIconWidth,
        pow(2, ceil(log2(idealIconWidth)))
      ))
    iconRect = CGRect(
      origin: CGPoint(x: -iconWidth / 2, y: -iconWidth / 2),
      size: CGSize(width: iconWidth, height: iconWidth)
    )

    let numWarpRows = 10
    let fraction = 1.0 / Float(numWarpRows)
    warpPoints = [vector_float2]()
    for row in 0...numWarpRows {
      for col in 0...numWarpRows {
        warpPoints.append(vector_float2(Float(col), Float(row)) * fraction)
      }
    }

    warp = SKWarpGeometryGrid(columns: numWarpRows, rows: numWarpRows)
      .replacingBySourcePositions(positions: warpPoints)
      .replacingByDestinationPositions(positions: warpPoints)
  }
}
