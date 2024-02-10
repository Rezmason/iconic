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

class AnimationView: SKView {

  class PlaceholderIconSource: IconSource {

    var image: NSImage

    init(for rect: CGRect) {
      let width = rect.width
      let shape = SKShapeNode(rect: rect, cornerRadius: width / 8)
      shape.strokeColor = SKColor.systemBlue
      shape.lineWidth = Double.maximum(width / 24, 24)
      let texture = SKView().texture(from: shape)!
      texture.usesMipmaps = true
      image = NSImage(cgImage: texture.cgImage(), size: rect.size)
    }

    func icon() async -> Icon? {
      return Icon(image: image)
    }
  }

  let maxIcons = 30
  let iconRect: CGRect

  var running = false
  var sprites = [SKSpriteNode]()
  let defaultSource: IconSource
  var source: IconSource

  var count = 0
  var lifespan = 0.0
  var scale = 0.0
  var aqua = 0.0

  var transparent = false {
    didSet {
      if transparent != oldValue {
        allowsTransparency = transparent
        scene!.backgroundColor = transparent ? .clear : .black
      }
    }
  }

  override init(frame: NSRect) {

    let width = min(1024, max(32, pow(2, ceil(log2(max(frame.width, frame.height))) - 2)))
    iconRect = CGRect(
      origin: CGPoint(x: -width / 2, y: -width / 2),
      size: CGSize(width: width, height: width)
    )
    defaultSource = PlaceholderIconSource(for: iconRect)
    source = defaultSource

    super.init(frame: frame)

    let scene = SKScene(size: frame.size)
    scene.backgroundColor = transparent ? .clear : .black
    //    scene.backgroundColor = debugBackgroundColor

    presentScene(scene)

    for _ in 0..<maxIcons {
      let sprite = SKSpriteNode(texture: nil, size: iconRect.size)
      sprite.isHidden = true
      scene.addChild(sprite)
      sprites.append(sprite)
    }

    settings.count += {
      let oldCount = self.count
      self.count = Int(mix(10, 30, $0))
      if self.running && self.count > oldCount {
        self.startIconAnimations(oldCount..<self.count)
      }
    }

    settings.lifespan += { self.lifespan = mix(15, 5, $0) }
    settings.scale += { self.scale = mix(0.15, 0.4, $0) }
    settings.aqua += { self.aqua = mix(0.0, 1.0, $0) }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func start() {
    if running {
      return
    }
    running = true
    startIconAnimations(0..<count)
  }

  func stop() {
    running = false
  }

  private func animate(_ index: Int) async {

    let sprite = sprites[index]

    if !running || index >= count {
      sprite.isHidden = true
      return
    }

    //    self.scene?.backgroundColor = debugBackgroundColor

    sprite.isHidden = false
    let duration = Double.random(in: (lifespan / 2)...lifespan)
    let (position, velocity) = createMotion()

    sprite.removeAllActions()
    sprite.alpha = 0
    sprite.position = position

    let approach = SKAction.customAction(withDuration: duration) { _, elapsedTime in
      sprite.zPosition = elapsedTime
      let depth = duration - elapsedTime
      sprite.setScale(self.scale / (1 + depth * 0.1))
    }

    let fade = SKAction.sequence([
      SKAction.fadeIn(withDuration: duration * 0.2),
      SKAction.wait(forDuration: duration * (1 - 0.2 * 2)),
      SKAction.fadeOut(withDuration: duration * 0.2),
    ])

    let move = SKAction.move(by: velocity, duration: duration)
    move.timingMode = .easeIn

    var actions = [approach, fade, move]

    sprite.zRotation = 0
    if Int.random(in: 0..<100) == 0 {
      sprite.zRotation = Double.random(in: 0...(.pi * 2))
      let direction = Bool.random() ? 1.0 : -1.0
      let amount = .pi * 2 * Double.random(in: 3...5)
      let twirl = SKAction.rotate(byAngle: amount * direction, duration: duration)
      actions.append(twirl)
    }

    let icon = await source.icon()
    sprite.texture = nil
    if let icon = icon {
      let bestRepImage = NSImage()
      bestRepImage.addRepresentation(
        icon.image.bestRepresentation(for: iconRect, context: nil, hints: nil)!
      )

      let texture = SKTexture(image: bestRepImage)  // As far as I can tell, this is what you're supposed to do
      texture.usesMipmaps = true
      texture.filteringMode = icon.pixelated ? .nearest : .linear
      sprite.texture = texture
    }

    await sprite.run(SKAction.group(actions))

    await self.animate(index)
  }

  private func createMotion() -> (CGPoint, CGVector) {

    let quadrantWidth = frame.width / 2
    let quadrantHeight = frame.height / 2

    var startPosition = CGPoint(
      x: Double.random(in: 0...quadrantWidth), y: Double.random(in: 0...quadrantHeight))
    var finalPosition = CGPoint(
      x: Double.random(in: 0...quadrantWidth), y: Double.random(in: 0...quadrantHeight))

    switch Int.random(in: 0..<3) {
    case 0:
      finalPosition.x *= -1
    case 1:
      finalPosition.y *= -1
    default:
      finalPosition.x *= -1
      finalPosition.y *= -1
    }

    if Bool.random() {
      startPosition.x *= -1
      finalPosition.x *= -1
    }
    if Bool.random() {
      startPosition.y *= -1
      finalPosition.y *= -1
    }

    finalPosition.x *= 0.75
    finalPosition.y *= 0.75

    let velocity = CGVector(
      dx: finalPosition.x - startPosition.x, dy: finalPosition.y - startPosition.y
    )
    startPosition.x += quadrantWidth
    startPosition.y += quadrantHeight

    return (startPosition, velocity)
  }

  private func startIconAnimations(_ range: Range<Int>) {
    for index in range {
      scene!.run(SKAction.wait(forDuration: Double.random(in: 0...Double(count)))) {
        Task {
          await self.animate(index)
        }
      }
    }
  }
}
