//
//  AnimationView.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import SpriteKit

private func mix(_ operand1: Double, _ operand2: Double, _ ratio: Double) -> Double {
  return (1 - ratio) * operand1 + ratio * operand2
}

class AnimationView: SKView {

  var running = false
  var cards = [Card]()
  var context: AnimationContext
  let defaultSource: IconSource
  var source: IconSource
  var settingsObservations = [NSKeyValueObservation]()
  var settings: Settings

  var transparent = false {
    didSet {
      if transparent != oldValue {
        allowsTransparency = transparent
        scene!.backgroundColor = transparent ? .clear : .black
      }
    }
  }

  init(frame: NSRect, settings: Settings) {
    context = AnimationContext(for: frame)
    defaultSource = PlaceholderIconSource(for: context.iconRect)
    source = defaultSource
    self.settings = settings
    super.init(frame: frame)

    let scene = SKScene(size: frame.size)
    scene.backgroundColor = transparent ? .clear : .black

    presentScene(scene)

    for _ in 0..<context.maxIcons {
      let card = Card(context)
      scene.addChild(card)
      cards.append(card)
    }

    settingsObservations.append(
      settings.observe(
        \Settings.count, options: .initial,
        changeHandler: { settings, _ in
          let context = self.context
          let oldCount = context.count
          context.count = Int(mix(10, 30, settings.count))
          if self.running && context.count > oldCount {
            self.startIconAnimations(oldCount..<context.count)
          }
        }))

    settingsObservations.append(
      settings.observe(
        \Settings.lifespan, options: .initial,
        changeHandler: { settings, _ in
          self.context.lifespan = mix(15, 5, settings.lifespan)
        }))

    settingsObservations.append(
      settings.observe(
        \Settings.scale, options: .initial,
        changeHandler: { settings, _ in
          self.context.scale = mix(0.5, 2.0, settings.scale)
        }))

    settingsObservations.append(
      settings.observe(
        \Settings.ripple, options: .initial,
        changeHandler: { settings, _ in
          self.context.ripple = mix(0.0, 0.1, settings.ripple)
        }))
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
