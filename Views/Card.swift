//
//  Card.swift
//  Iconic
//
//  Created by Jeremy Sachs on 3/9/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import SpriteKit

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
    removeAllActions()
    alpha = 0
    let duration = Double.random(in: (context.lifespan / 2)...context.lifespan)
    await self.run(
      SKAction.group([
        makeMove(duration),
        makeRipple(duration),
        makeFade(duration),
      ]))
  }

  func makeMove(_ duration: Double) -> SKAction {
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

    return SKAction.customAction(withDuration: duration) { _, elapsedTime in
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
  }

  func makeRipple(_ duration: Double) -> SKAction {
    return SKAction.customAction(withDuration: duration) { _, elapsedTime in

      if self.context.ripple == 0 {
        self.warpGeometry = nil
        return
      }

      let now = Float(elapsedTime)
      let rippleScale = expf(-6.0 * powf(now / Float(duration), 2.0)) * Float(self.context.ripple)
      let rippleAngle = atan2f(Float(self.position.x), Float(self.position.y))
      let warped = self.context.warpPoints.map({
        self.applyRipple(to: $0, at: now, from: rippleAngle, by: rippleScale)
      })
      self.warpGeometry = self.context.warp.replacingByDestinationPositions(positions: warped)
    }
  }

  func makeFade(_ duration: Double) -> SKAction {
    return SKAction.sequence([
      SKAction.fadeIn(withDuration: duration * 0.2),
      SKAction.wait(forDuration: duration * (1 - 0.2 * 2)),
      SKAction.fadeOut(withDuration: duration * 0.2),
    ])
  }
}
