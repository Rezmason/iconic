//
//  AnimationView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import SpriteKit

// var debugBackgroundColor: NSColor = .yellow

private func mix(_ operand1: Double, _ operand2: Double, _ ratio: Double) -> Double {
  return (1 - ratio) * operand1 + ratio * operand2
}

private func randomPoint() -> vector_float2 {
  return vector_float2(.random(in: 0...1), .random(in: 0...1))
}

private func sinv2(_ value: vector_float2) -> vector_float2 {
  return vector_float2(sinf(value.x), sinf(value.y))
}

class PlaceholderIconSource: IconSource {

  var image: NSImage

  init(for rect: CGRect) {
    let width = rect.width
    let shape = SKShapeNode(rect: rect, cornerRadius: width / 8)

    shape.strokeColor = SKColor.systemBlue
    shape.lineWidth = Double.maximum(width / 24, 16)
    let texture = SKView().texture(from: shape)!
    texture.usesMipmaps = true
    image = NSImage(cgImage: texture.cgImage(), size: rect.size)
  }

  func icon() async -> Icon? {
    return Icon(image: image)
  }
}

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
  var aqua = 0.0

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

class Card: SKEffectNode {
  private let shape: SKShapeNode
  private let sprite: SKSpriteNode
  private let context: AnimationContext

  var icon: Icon? {
    didSet {
      sprite.texture = nil
      guard let icon = icon else { return }
      let bestRepImage = NSImage()
      bestRepImage.addRepresentation(
        icon.image.bestRepresentation(for: context.iconRect, context: nil, hints: nil)!
      )
      let texture = SKTexture(image: bestRepImage)  // As far as I can tell, this is what you're supposed to do
      texture.usesMipmaps = true
      texture.filteringMode = icon.pixelated ? .nearest : .linear
      sprite.texture = texture
    }
  }

  init(_ context: AnimationContext) {
    shape = SKShapeNode(circleOfRadius: CGFloat(context.iconRect.width * 2.squareRoot() / 2))
    shape.lineWidth = 0
    sprite = SKSpriteNode(texture: nil, size: context.iconRect.size)
    self.context = context
    super.init()
    isHidden = true
    addChild(shape)
    addChild(sprite)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Unimplemented")
  }

  private func applyRipple(
    to point: vector_float2, at time: Float, from angle: Float, by amount: Float
  ) -> vector_float2 {
    let cosine = cos(angle)
    let sine = sin(angle)
    let rotated =
      vector_float2(
        cosine * point.x - sine * point.y,
        sine * point.x + cosine * point.y
      ) * vector_float2(8, 6)

    let displacement = vector_float2(
      sinf(rotated.x + 11 * time),
      sinf(rotated.y + 7 * time)
    )
    return point + displacement * amount
  }

  func runAnimation() async {
    let duration = Double.random(in: (context.lifespan / 2)...context.lifespan)

    removeAllActions()
    alpha = 0

    let initialPosition = vector_double3(
      .random(in: context.backRange.x),
      .random(in: context.backRange.y),
      context.backZ
    )

    let finalPosition = vector_double3(
      .random(in: context.frontRange.x),
      .random(in: context.frontRange.y),
      context.frontZ
    )

    let three = vector_double3(1, 1, 1)
    self.position = CGPoint(x: initialPosition.x, y: initialPosition.y)
    sprite.zRotation = 0
    let isTwirling = Float.random(in: 0..<100) < 0.3
    let rotationSpeed = (Bool.random() ? 1.0 : -1.0) * 4
    shape.isHidden = !isTwirling

    let move = SKAction.customAction(withDuration: duration) { _, elapsedTime in
      let worldPosition = simd_mix(initialPosition, finalPosition, three * elapsedTime / duration)
      let perspectiveScale = self.context.focalLength / worldPosition.z
      self.zPosition = -worldPosition.z
      self.position = CGPoint(
        x: worldPosition.x * perspectiveScale,
        y: worldPosition.y * perspectiveScale
      )
      let scale = self.context.scale * perspectiveScale
      self.sprite.setScale(scale)
      self.shape.setScale(scale)

      if isTwirling {
        self.sprite.zRotation = rotationSpeed * elapsedTime
      }
    }

    let ripple = SKAction.customAction(withDuration: duration) { _, elapsedTime in

      if self.context.aqua == 0 {
        self.warpGeometry = nil
        return
      }

      let now = Float(elapsedTime)
      let rippleScale = expf(-6.0 * powf(now / Float(duration), 2.0)) * Float(self.context.aqua)
      let rippleAngle = atan2f(Float(self.position.x), Float(self.position.y))
      let warped = self.context.warpPoints.map({
        self.applyRipple(to: $0, at: now, from: rippleAngle, by: rippleScale)
      })
      self.warpGeometry = self.context.warp.replacingByDestinationPositions(positions: warped)
    }

    let fade = SKAction.sequence([
      SKAction.fadeIn(withDuration: duration * 0.2),
      SKAction.wait(forDuration: duration * (1 - 0.2 * 2)),
      SKAction.fadeOut(withDuration: duration * 0.2),
    ])

    await self.run(SKAction.group([move, ripple, fade]))
  }
}

class AnimationView: SKView {

  var running = false
  var cards = [Card]()
  var context: AnimationContext
  let defaultSource: IconSource
  var source: IconSource

  var transparent = false {
    didSet {
      if transparent != oldValue {
        allowsTransparency = transparent
        scene!.backgroundColor = transparent ? .clear : .black
      }
    }
  }

  override init(frame: NSRect) {

    context = AnimationContext(for: frame)
    defaultSource = PlaceholderIconSource(for: context.iconRect)
    source = defaultSource
    super.init(frame: frame)

    let scene = SKScene(size: frame.size)
    scene.backgroundColor = transparent ? .clear : .black
    //    scene.backgroundColor = debugBackgroundColor

    presentScene(scene)

    for _ in 0..<context.maxIcons {
      let card = Card(context)
      scene.addChild(card)
      cards.append(card)
    }

    settings.count += {
      let context = self.context
      let oldCount = context.count
      context.count = Int(mix(10, 30, $0))
      if self.running && context.count > oldCount {
        self.startIconAnimations(oldCount..<context.count)
      }
    }

    settings.lifespan += { self.context.lifespan = mix(15, 5, $0) }
    settings.scale += { self.context.scale = mix(0.5, 2.0, $0) }
    settings.aqua += { self.context.aqua = mix(0.0, 0.1, $0) }
  }

  required init?(coder: NSCoder) {
    fatalError("Unimplemented")
  }

  func start() {
    if running {
      return
    }
    running = true
    startIconAnimations(0..<context.count)
  }

  func stop() {
    running = false
  }

  private func animate(_ index: Int) async {
    let card = cards[index]
    card.isHidden = !running || index >= context.count
    if card.isHidden {
      return
    }
    //    self.scene?.backgroundColor = debugBackgroundColor
    card.icon = await source.icon()
    await card.runAnimation()
    await self.animate(index)
  }

  private func startIconAnimations(_ range: Range<Int>) {
    for index in range {
      scene!.run(SKAction.wait(forDuration: Double.random(in: 0...Double(context.count)))) {
        Task {
          await self.animate(index)
        }
      }
    }
  }
}
