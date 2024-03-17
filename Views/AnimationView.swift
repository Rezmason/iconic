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
    settings.ripple += { self.context.ripple = mix(0.0, 0.1, $0) }
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
