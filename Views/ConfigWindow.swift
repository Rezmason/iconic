//
//  ConfigWindow.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import ScreenSaver
import SpriteKit

final class ConfigWindowController: NSWindowController {

  private var snapshot = Settings.defaults
  private var settingsObservations = [NSKeyValueObservation]()
  private var sliderFields = [NSSlider: WritableKeyPath<Settings, Double>]()
  private var selectedSourceID: String?

  private var animation: AnimationView?
  private var source: IconSource?

  private static let iconViewRect = NSRect(x: 0, y: 0, width: 128, height: 128)
  private let iconViews = Array(0..<60).map { _ in IconViewItem() }

  @IBOutlet weak var animCountSlider: NSSlider!
  @IBOutlet weak var animLifespanSlider: NSSlider!
  @IBOutlet weak var animScaleSlider: NSSlider!
  @IBOutlet weak var animRippleSlider: NSSlider!
  @IBOutlet weak var animationDemo: NSView!

  @IBOutlet weak var sourceSidebar: NSTableView!
  @IBOutlet weak var sourceToggle: NSSwitch!
  @IBOutlet weak var sourceDescription: NSTextField!
  @IBOutlet weak var sourceIconCollection: NSCollectionView!

  private class IconViewItem: NSCollectionViewItem {

    var spinner: NSProgressIndicator?
    var source: IconSource?

    var icon: NSImage? {
      didSet {
        imageView?.image = icon
        if icon == nil {
          spinner?.startAnimation(nil)
        } else {
          spinner?.stopAnimation(nil)
        }
      }
    }

    override func loadView() {
      let imageView = NSImageView(frame: iconViewRect)
      imageView.imageAlignment = .alignCenter
      imageView.imageScaling = .scaleProportionallyUpOrDown
      imageView.autoresizingMask = [.width, .height]
      imageView.image = icon
      self.imageView = imageView

      let spinner = NSProgressIndicator(frame: iconViewRect.insetBy(dx: 16, dy: 16))
      spinner.style = .spinning
      if #available(macOS 11.0, *) {
        spinner.controlSize = .large
      } else {
        spinner.controlSize = .regular
      }
      spinner.isDisplayedWhenStopped = false
      spinner.isIndeterminate = true
      spinner.autoresizingMask = [.width, .height]
      self.spinner = spinner
      spinner.usesThreadedAnimation = true
      if icon == nil {
        spinner.startAnimation(nil)
      }

      let view = NSView(frame: iconViewRect)
      view.addSubview(imageView)
      view.addSubview(spinner)
      view.autoresizesSubviews = true
      self.view = view
    }

    deinit {
      self.source = nil
      self.imageView?.image = nil
    }
  }

  var importedSources = [String]()
  var sourceSidebarElements = [SidebarElement]()

  override var windowNibName: String {
    return "ConfigSheet"
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    snapshot = settings.snapshot()
    buildIconSourceCollection()
    buildIconSourceSidebarElements()
    buildIconSourceSidebar()
    buildAnimationView()
  }

  deinit {
    settingsObservations.removeAll()
  }

  private func buildIconSourceCollection() {
    sourceIconCollection.dataSource = self
    sourceIconCollection.delegate = self

    let layout = NSCollectionViewGridLayout()
    layout.margins = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    layout.maximumNumberOfColumns = 3
    layout.minimumItemSize = NSSize(width: 64, height: 64)
    layout.maximumItemSize = NSSize(width: 128, height: 128)
    sourceIconCollection.collectionViewLayout = layout
  }

  private func buildIconSourceSidebarElements() {
    importedSources = []  // TODO: support user-imported sources

    let importedSourceSidebar: [SidebarElement] = [
      .group(
        name: "Custom",
        contents: importedSources.map({ importID in
          .entry(
            sourceID: importID,
            name: importID,
            description: "",
            symbol: "folder"
          )
        })
      )
    ]

    sourceSidebarElements =
      ([
        defaultSidebar,
        importedSourceSidebar,
      ].flatMap({ $0 }).compactMap({ element in
        switch element {
        case .entry:
          return [element]
        case .group(_, let contents) where contents.count > 0:
          return [[element], contents].flatMap { $0 }
        default:
          return []
        }
      }) as [[SidebarElement]]).flatMap({ $0 })
      .filter({ element in
        switch element {
        case .group:
          return true
        case .entry(_, _, _, _, let requirement):
          if let requirement = requirement {
            return requirement()
          }
          return true
        }
      })
  }

  private func buildIconSourceSidebar() {

    sourceSidebar.allowsEmptySelection = false
    sourceSidebar.allowsMultipleSelection = false

    sourceSidebar.dataSource = self
    sourceSidebar.delegate = self

    settingsObservations.append(
      settings.observe(
        \Settings.sources, options: .initial,
        changeHandler: { settings, _ in
          if let sourceID = self.selectedSourceID {
            self.sourceToggle.state = settings.sources.contains(sourceID) ? .on : .off
          }
        }))

    let defaultRow = sourceSidebarElements.firstIndex { !isGroup($0) }!
    let indices = IndexSet.init(integer: defaultRow)
    sourceSidebar.selectRowIndexes(indices, byExtendingSelection: false)
    sourceSidebar.scrollRowToVisible(defaultRow)
  }

  private func buildAnimationView() {

    sliderFields = [
      animCountSlider: \Settings.count,
      animLifespanSlider: \Settings.lifespan,
      animScaleSlider: \Settings.scale,
      animRippleSlider: \Settings.ripple,
    ]

    for (slider, keyPath) in sliderFields {
      settingsObservations.append(
        settings.observe(
          keyPath, options: [.initial, .new],
          changeHandler: { _, change in
            slider.doubleValue = change.newValue ?? 0.0
          }))
    }

    let animation = AnimationView(frame: animationDemo.frame)
    animation.transparent = true
    animationDemo.addSubview(animation)
    self.animation = animation

    animation.start()
  }

  @IBAction func handlingNSSwitchChanges(_ sender: Any) {
    guard let sourceID = selectedSourceID else {
      return
    }
    settings.sources.toggle(sourceID, to: sourceToggle.state == .on)
  }

  @IBAction func handlingNSSliderChanges(_ sender: Any) {
    if let slider = sender as? NSSlider {
      settings[keyPath: sliderFields[slider]!] = slider.doubleValue
    }
  }

  @IBAction func ok(_ sender: Any?) {
    snapshot = settings.snapshot()
    settings.saveToDisk()
    self.window?.sheetParent?.endSheet(self.window!)
  }

  @IBAction func cancel(_ sender: Any?) {
    settings.overwrite(with: snapshot)
    self.window?.sheetParent?.endSheet(self.window!)
  }

  @IBAction func restoreDefaults(_ sender: Any?) {
    settings.overwrite(with: .defaults)
    if let sourceID = selectedSourceID {
      sourceToggle.state = settings.sources.contains(sourceID) ? .on : .off
    } else {
      let defaultRow = sourceSidebarElements.firstIndex { !isGroup($0) }!
      let indices = IndexSet.init(integer: defaultRow)
      sourceSidebar.selectRowIndexes(indices, byExtendingSelection: false)
      sourceSidebar.scrollRowToVisible(defaultRow)
    }
  }
}

extension NSUserInterfaceItemIdentifier {
  fileprivate static let groupView = NSUserInterfaceItemIdentifier("SidebarGroupView")
  fileprivate static let entryView = NSUserInterfaceItemIdentifier("SidebarEntryView")
}

extension ConfigWindowController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return sourceSidebarElements.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int)
    -> Any?
  {
    return sourceSidebarElements[row]
  }
}

extension ConfigWindowController: NSTableViewDelegate {

  func isGroup(_ element: SidebarElement) -> Bool {
    if case .group = element {
      return true
    }
    return false
  }

  func isGroup(row: Int) -> Bool {
    return isGroup(sourceSidebarElements[row])
  }

  func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
    return isGroup(row: row)
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    switch sourceSidebarElements[row] {
    case let .group(name, _):
      let groupView =
        tableView.makeView(withIdentifier: .groupView, owner: nil) as? NSTableCellView
      if let textField = groupView?.textField {
        textField.stringValue = name
        textField.sizeToFit()
      }
      return groupView
    case let .entry(_, name, _, symbol, _):
      let entryView =
        tableView.makeView(withIdentifier: .entryView, owner: nil) as? NSTableCellView
      if let textField = entryView?.textField {
        textField.stringValue = name
        textField.sizeToFit()
      }
      if #available(macOS 11.0, *), let imageView = entryView?.imageView {
        imageView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
      }
      return entryView
    }
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return !isGroup(row: row)
  }

  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return isGroup(row: row) ? 17 : 34
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let selectedElement = sourceSidebarElements[sourceSidebar.selectedRow]
    guard case let .entry(sourceID, _, description, _, _) = selectedElement else {
      return
    }

    selectedSourceID = sourceID
    sourceToggle.state = settings.sources.contains(sourceID) ? .on : .off
    sourceDescription.stringValue = description

    Task.detached {
      await self.populateIcons()
    }
  }

  func populateIcons() async {
    guard let sourceID = selectedSourceID else {
      return
    }
    let source = getSource(for: sourceID)

    for iconView in iconViews {
      iconView.icon = nil
    }

    // Not parallel, but neither are icon sources I believe
    for iconView in iconViews {
      if let icon = await source?.icon() {
        iconView.icon = icon.image
        // TODO: icon.pixelated
      }
    }
  }
}

extension ConfigWindowController: NSCollectionViewDataSource {
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return iconViews.count
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    let iconView = iconViews[indexPath.item]
    iconView.view.isHidden = false
    return iconView
  }
}

extension ConfigWindowController: NSCollectionViewDelegate {

}
