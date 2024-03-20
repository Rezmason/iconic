//
//  ConfigWindow.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2023 Rezmason.net. All rights reserved.
//

import ScreenSaver

final class ConfigWindowController: NSWindowController {

  private enum SidebarElement: Codable {
    case group(name: String, contents: [SidebarElement])
    case entry(sourceID: String, display: IconSourceDisplay)
  }

  private var snapshot = Settings.defaults
  private var settingsObservations = [NSKeyValueObservation]()
  private var sliderFields = [NSSlider: WritableKeyPath<Settings, Double>]()
  private var selectedSourceID: String?

  private weak var animation: AnimationView?
  private weak var factory: IconFactory?
  private weak var settings: Settings?
  private let iconViews = Array(0..<60).map { _ in IconViewItem() }
  private let iconSet = IconSet()

  @IBOutlet weak var animCountSlider: NSSlider!
  @IBOutlet weak var animLifespanSlider: NSSlider!
  @IBOutlet weak var animScaleSlider: NSSlider!
  @IBOutlet weak var animRippleSlider: NSSlider!
  @IBOutlet weak var animationDemo: NSView!

  @IBOutlet weak var sourceSidebar: NSTableView!
  @IBOutlet weak var sourceToggle: NSSwitch!
  @IBOutlet weak var sourceDescription: NSTextField!
  @IBOutlet weak var sourceIconCollection: NSCollectionView!

  private var sourceSidebarElements = [SidebarElement]()

  init(factory: IconFactory, settings: Settings) {
    self.factory = factory
    self.settings = settings
    super.init(window: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("Unimplemented")
  }

  override var windowNibName: String { "ConfigSheet" }

  override var window: NSWindow? {
    get {
      if super.window == nil {
        Bundle(for: ConfigWindowController.self).loadNibNamed(
          windowNibName,
          owner: self,
          topLevelObjects: nil
        )
      }
      return super.window
    }
    set { super.window = newValue }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setup()
  }

  deinit {
    tearDown()
  }

  private func setup() {
    guard
      let settings = settings,
      let factory = factory
    else {
      fatalError("Config sheet must be initialized with settings and factory objects.")
    }
    snapshot = settings.snapshot()
    buildIconSourceCollection()
    buildIconSourceSidebarElements(withFactory: factory)
    buildIconSourceSidebar(withSettings: settings)
    buildAnimationView(withSettings: settings)
  }

  private func tearDown() {
    settingsObservations.forEach { $0.invalidate() }
    settingsObservations.removeAll()

    sourceIconCollection?.dataSource = nil
    sourceSidebarElements = []
    sourceSidebar?.dataSource = nil
    sourceSidebar?.delegate = nil
    sliderFields = [:]

    animation?.stop()
    animation?.removeFromSuperview()
    animation = nil

    iconViews.forEach({ $0.icon = nil })
    iconSet.removeAll()

    super.window?.sheetParent?.endSheet(window!)
    super.window = nil
  }

  private func buildIconSourceCollection() {
    sourceIconCollection.dataSource = self

    let layout = NSCollectionViewGridLayout()
    layout.margins = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 8
    layout.maximumNumberOfColumns = 3
    layout.minimumItemSize = NSSize(width: 64, height: 64)
    layout.maximumItemSize = NSSize(width: 128, height: 128)
    sourceIconCollection.collectionViewLayout = layout
  }

  private func buildIconSourceSidebarElements(withFactory factory: IconFactory) {

    let builtInSidebar: [SidebarElement] = ConfigWindowController.loadBuiltInSidebar()

    let includedSpritesheetSidebar: [SidebarElement] = [
      .group(
        name: "Reliquary",
        contents: factory.includedSpritesheets.compactMap({ (key, def) in
          return .entry(
            sourceID: key,
            display: def.display
          )
        }).sorted(by: { entry1, entry2 in
          guard
            case let .entry(_, display1) = entry1,
            case let .entry(_, display2) = entry2
          else {
            return false
          }
          return display1.name < display2.name
        })
      )
    ]

    let importedSourceSidebar: [SidebarElement] = []  // TODO

    sourceSidebarElements =
      ([
        builtInSidebar,
        includedSpritesheetSidebar,
        importedSourceSidebar,
      ].reduce([], +).compactMap({ element in
        switch element {
        case .entry:
          return [element]
        case .group(_, let contents) where contents.count > 0:
          return [[element], contents].flatMap { $0 }
        default:
          return []
        }
      }) as [[SidebarElement]]).flatMap({ $0 })
  }

  private func buildIconSourceSidebar(withSettings settings: Settings) {

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

  private func buildAnimationView(withSettings settings: Settings) {

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

    let animation = AnimationView(frame: animationDemo.frame, settings: settings)
    animation.transparent = true
    animationDemo.addSubview(animation)
    self.animation = animation
    animation.start()
  }

  @IBAction func handlingNSSwitchChanges(_ sender: Any) {
    guard let sourceID = selectedSourceID else { return }
    settings?.sources.toggle(sourceID, to: sourceToggle.state == .on)
  }

  @IBAction func handlingNSSliderChanges(_ sender: Any) {
    guard let slider = sender as? NSSlider else { return }
    settings?[keyPath: sliderFields[slider]!] = slider.doubleValue
  }

  @IBAction func ok(_ sender: Any?) {
    guard let settings = settings else { return }
    snapshot = settings.snapshot()
    settings.saveToDisk()
    tearDown()
  }

  @IBAction func cancel(_ sender: Any?) {
    guard let settings = settings else { return }
    settings.overwrite(with: snapshot)
    tearDown()
  }

  @IBAction func restoreDefaults(_ sender: Any?) {
    guard let settings = settings else { return }
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

  private static func loadBuiltInSidebar() -> [SidebarElement] {
    let bundle = Bundle(for: ConfigWindowController.self)
    guard
      let data = NSDataAsset(name: "builtin_sidebar", bundle: bundle)?.data,
      let json = try? JSONDecoder().decode([SidebarElement].self, from: data)
    else {
      return []
    }
    return json
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

  private func isGroup(_ element: SidebarElement) -> Bool {
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
    case let .entry(_, display):
      let entryView =
        tableView.makeView(withIdentifier: .entryView, owner: nil) as? NSTableCellView
      if let textField = entryView?.textField {
        textField.stringValue = display.name
        textField.sizeToFit()
      }
      if #available(macOS 11.0, *), let imageView = entryView?.imageView {
        imageView.image = NSImage(systemSymbolName: display.symbol, accessibilityDescription: nil)
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
    guard let settings = settings else { return }
    let selectedElement = sourceSidebarElements[sourceSidebar.selectedRow]
    guard case let .entry(sourceID, display) = selectedElement else { return }

    selectedSourceID = sourceID
    sourceToggle.state = settings.sources.contains(sourceID) ? .on : .off
    sourceDescription.stringValue = display.description

    Task.detached {
      await self.populateIcons()
    }
  }

  func populateIcons() async {
    guard let sourceID = selectedSourceID else { return }
    guard let factory = factory else { return }

    for iconView in iconViews {
      iconSet.remove(iconView.icon)
      iconView.icon = nil
    }
    let source = factory.source(for: sourceID)
    // Not parallel, but neither are icon sources I believe
    for iconView in iconViews {
      iconView.icon = await source?.supplyIcon(notWithin: iconSet)
      iconSet.add(iconView.icon)
    }
  }
}

extension ConfigWindowController: NSCollectionViewDataSource {
  func collectionView(
    _ collectionView: NSCollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
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
