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
  let iconScene: SKScene
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
        iconScene.backgroundColor = transparent ? .clear : .black
      }
    }
  }

  init(frame: NSRect, settings: Settings) {
    context = AnimationContext(for: frame)
    defaultSource = PlaceholderIconSource(for: context.iconRect)
    source = defaultSource
    iconScene = SKScene(size: frame.size)
    self.settings = settings
    super.init(frame: frame)
    presentScene(iconScene)

    iconScene.backgroundColor = transparent ? .clear : .black

    for _ in 0..<context.maxIcons {
      cards.append(Card(context))
    }

    settingsObservations.append(
      settings.observe(
        \Settings.count, options: .initial,
        changeHandler: { [weak self] settings, _ in
          guard let self = self else { return }
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
        changeHandler: { [weak self] settings, _ in
          guard let self = self else { return }
          self.context.lifespan = mix(15, 5, settings.lifespan)
        }))

    settingsObservations.append(
      settings.observe(
        \Settings.scale, options: .initial,
        changeHandler: { [weak self] settings, _ in
          guard let self = self else { return }
          self.context.scale = mix(0.5, 2.0, settings.scale)
        }))

    settingsObservations.append(
      settings.observe(
        \Settings.ripple, options: .initial,
        changeHandler: { [weak self] settings, _ in
          guard let self = self else { return }
          self.context.ripple = mix(0.0, 0.1, settings.ripple)
        }))
  }

  required init?(coder: NSCoder) {
    fatalError("Unimplemented")
  }

  deinit {
    stop()
    presentScene(nil)
    settingsObservations.removeAll()
  }

  func start() {
    if running { return }
    running = true
    cards.forEach { iconScene.addChild($0) }
    startIconAnimations(0..<context.count)
  }

  func stop() {
    running = false
    for card in cards {
      card.removeFromParent()
      card.icon = nil
    }
    source = defaultSource
  }

  private func animate(_ index: Int) async {
    let card = cards[index]
    card.isHidden = !running || index >= context.count
    if card.isHidden { return }
    card.icon = await source.icon()
    card.runAnimation { [weak self, weak card] in
      card?.icon = nil
      guard let self = self else { return }
      Task {
        await self.animate(index)
      }
    }
  }

  private func startIconAnimations(_ range: Range<Int>) {
    for index in range {
      let duration = Double.random(in: 0...Double(context.count))
      iconScene.run(SKAction.wait(forDuration: duration)) { [weak self] in
        guard let self = self else { return }
        Task {
          await self.animate(index)
        }
      }
    }
  }
}
