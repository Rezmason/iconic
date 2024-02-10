//
//  HFSFileTypeIconSource.swift
//  Iconic
//
//  Created by Jeremy Sachs on 1/24/24.
//  Copyright © 2024 Rezmason.net. All rights reserved.
//

import Cocoa

extension String {
  fileprivate var fourCharCodeValue: OSType {
    var result = 0
    if let data = self.data(using: String.Encoding.macOSRoman) {
      data.withUnsafeBytes({ rawBytes in
        let bytes = rawBytes.bindMemory(to: UInt8.self)
        for index in 0..<data.count {
          result = result << 8 + Int(bytes[index])
        }
      })
    }
    return OSType(result)
  }
}

class HFSFileTypeIconSource: IconSource {

  private let storage: IconStorage<String>

  init() {
    storage = IconStorage(with: { return Icon(image: NSWorkspace.shared.icon(forFileType: $0)) })
    let fileTypes = hfsIcons.values.compactMap { NSFileTypeForHFSTypeCode($0.fourCharCodeValue) }
    Task.detached { await self.storage.add(contentsOf: fileTypes) }
  }

  func icon() async -> Icon? {
    return await storage.icon()
  }
}

private let hfsIcons = [
  /* Generic Finder icons */
  "ClipboardIcon": "CLIP",
  "ClippingUnknownTypeIcon": "clpu",
  "ClippingPictureTypeIcon": "clpp",
  "ClippingTextTypeIcon": "clpt",
  "ClippingSoundTypeIcon": "clps",
  "DesktopIcon": "desk",
  "FinderIcon": "FNDR",
  "ComputerIcon": "root",
  "FontSuitcaseIcon": "FFIL",
  "FullTrashIcon": "ftrh",
  //  "GenericApplicationIcon": "APPL",
  "GenericCDROMIcon": "cddr",
  "GenericControlPanelIcon": "APPC",
  "GenericControlStripModuleIcon": "sdev",
  "GenericComponentIcon": "thng",
  "GenericDeskAccessoryIcon": "APPD",
  "GenericDocumentIcon": "docu",
  "GenericEditionFileIcon": "edtf",
  "GenericExtensionIcon": "INIT",
  "GenericFileServerIcon": "srvr",
  "GenericFontIcon": "ffil",
  "GenericFontScalerIcon": "sclr",
  "GenericFloppyIcon": "flpy",
  "GenericHardDiskIcon": "hdsk",
  "GenericIDiskIcon": "idsk",
  "GenericRemovableMediaIcon": "rmov",
  "GenericMoverObjectIcon": "movr",
  "GenericPCCardIcon": "pcmc",
  "GenericPreferencesIcon": "pref",
  "GenericQueryDocumentIcon": "qery",
  "GenericRAMDiskIcon": "ramd",
  "GenericSharedLibaryIcon": "shlb",
  "GenericStationeryIcon": "sdoc",
  "GenericSuitcaseIcon": "suit",
  "GenericURLIcon": "gurl",
  "GenericWORMIcon": "worm",
  "InternationalResourcesIcon": "ifil",
  "KeyboardLayoutIcon": "kfil",
  "SoundFileIcon": "sfil",
  "SystemSuitcaseIcon": "zsys",
  "TrashIcon": "trsh",
  "TrueTypeFontIcon": "tfil",
  "TrueTypeFlatFontIcon": "sfnt",
  "TrueTypeMultiFlatFontIcon": "ttcf",
  "UserIDiskIcon": "udsk",
  "UnknownFSObjectIcon": "unfs",

  /* Internet locations */
  "InternetLocationHTTPIcon": "ilht",
  "InternetLocationFTPIcon": "ilft",
  "InternetLocationAppleShareIcon": "ilaf",
  "InternetLocationAppleTalkZoneIcon": "ilat",
  "InternetLocationFileIcon": "ilfi",
  "InternetLocationMailIcon": "ilma",
  "InternetLocationNewsIcon": "ilnw",
  "InternetLocationNSLNeighborhoodIcon": "ilns",
  "InternetLocationGenericIcon": "ilge",

  /* Folders */
  "GenericFolderIcon": "fldr",
  "DropFolderIcon": "dbox",
  "MountedFolderIcon": "mntd",
  "OpenFolderIcon": "ofld",
  "OwnedFolderIcon": "ownd",
  "PrivateFolderIcon": "prvf",
  "SharedFolderIcon": "shfl",

  /* Sharing Privileges icons */
  "SharingPrivsNotApplicableIcon": "shna",
  "SharingPrivsReadOnlyIcon": "shro",
  "SharingPrivsReadWriteIcon": "shrw",
  "SharingPrivsUnknownIcon": "shuk",
  "SharingPrivsWritableIcon": "writ",

  /* Users and Groups icons */
  "UserFolderIcon": "ufld",
  "WorkgroupFolderIcon": "wfld",
  "GuestUserIcon": "gusr",
  "UserIcon": "user",
  "OwnerIcon": "susr",
  "GroupIcon": "grup",

  /* Special folders */
  "AppearanceFolderIcon": "appr",
  "AppleExtrasFolderIcon": "aexƒ",
  "AppleMenuFolderIcon": "amnu",
  "ApplicationsFolderIcon": "apps",
  "ApplicationSupportFolderIcon": "asup",
  "AssistantsFolderIcon": "astƒ",
  "ColorSyncFolderIcon": "prof",
  "ContextualMenuItemsFolderIcon": "cmnu",
  "ControlPanelDisabledFolderIcon": "ctrD",
  "ControlPanelFolderIcon": "ctrl",
  "ControlStripModulesFolderIcon": "sdvƒ",
  "DocumentsFolderIcon": "docs",
  "ExtensionsDisabledFolderIcon": "extD",
  "ExtensionsFolderIcon": "extn",
  "FavoritesFolderIcon": "favs",
  "FontsFolderIcon": "font",
  "HelpFolderIcon": "ƒhlp",
  "InternetFolderIcon": "intƒ",
  "InternetPlugInFolderIcon": "ƒnet",
  "InternetSearchSitesFolderIcon": "issf",
  "LocalesFolderIcon": "ƒloc",
  "MacOSReadMeFolderIcon": "morƒ",
  "PublicFolderIcon": "pubf",
  "PreferencesFolderIcon": "prfƒ",
  "PrinterDescriptionFolderIcon": "ppdf",
  "PrinterDriverFolderIcon": "ƒprd",
  "PrintMonitorFolderIcon": "prnt",
  "RecentApplicationsFolderIcon": "rapp",
  "RecentDocumentsFolderIcon": "rdoc",
  "RecentServersFolderIcon": "rsrv",
  "ScriptingAdditionsFolderIcon": "ƒscr",
  "SharedLibrariesFolderIcon": "ƒlib",
  "ScriptsFolderIcon": "scrƒ",
  "ShutdownItemsDisabledFolderIcon": "shdD",
  "ShutdownItemsFolderIcon": "shdf",
  "SpeakableItemsFolder": "spki",
  "StartupItemsDisabledFolderIcon": "strD",
  "StartupItemsFolderIcon": "strt",
  "SystemExtensionDisabledFolderIcon": "macD",
  "SystemFolderIcon": "macs",
  "TextEncodingsFolderIcon": "ƒtex",
  "UsersFolderIcon": "usrƒ",
  "UtilitiesFolderIcon": "utiƒ",
  "VoicesFolderIcon": "fvoc",

  /* Badges */
  //  "AppleScriptBadgeIcon": "scrp",
  //  "LockedBadgeIcon": "lbdg",
  //  "MountedBadgeIcon": "mbdg",
  //  "SharedBadgeIcon": "sbdg",
  //  "AliasBadgeIcon": "abdg",
  //  "AlertCautionBadgeIcon": "cbdg",

  /* Alert icons */
  "AlertNoteIcon": "note",
  "AlertCautionIcon": "caut",
  "AlertStopIcon": "stop",

  /* Networking icons */
  "AppleTalkIcon": "atlk",
  "AppleTalkZoneIcon": "atzn",
  "AFPServerIcon": "afps",
  "FTPServerIcon": "ftps",
  "HTTPServerIcon": "htps",
  "GenericNetworkIcon": "gnet",
  "IPFileServerIcon": "isrv",

  /* Toolbar icons */
  "ToolbarCustomizeIcon": "tcus",
  "ToolbarDeleteIcon": "tdel",
  "ToolbarFavoritesIcon": "tfav",
  "ToolbarHomeIcon": "thom",

  /* Other icons */
  "AppleLogoIcon": "capl",
  "AppleMenuIcon": "sapl",
  //  "BackwardArrowIcon": "baro",
  "FavoriteItemsIcon": "favr",
  //  "ForwardArrowIcon": "faro",
  //  "GridIcon": "grid",
  //  "HelpIcon": "help",
  //  "KeepArrangedIcon": "arng",
  //  "LockedIcon": "lock",
  "NoFilesIcon": "nfil",
  "NoFolderIcon": "nfld",
  //  "NoWriteIcon": "nwrt",
  "ProtectedApplicationFolderIcon": "papp",
  "ProtectedSystemFolderIcon": "psys",
  //  "RecentItemsIcon": "rcnt",
  "ShortcutIcon": "shrt",
  "SortAscendingIcon": "asnd",
  "SortDescendingIcon": "dsnd",
  //  "UnlockedIcon": "ulck",
  "ConnectToIcon": "cnct",
  //  "GenericWindowIcon": "gwin",
  //  "QuestionMarkIcon": "ques",
  "DeleteAliasIcon": "dali",
  "EjectMediaIcon": "ejec",
  "BurningIcon": "burn",
    //  "RightContainerArrowIcon": "rcar",
]
