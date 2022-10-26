//
// AppMenu.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

class AppMenu: NSMenu {

    private lazy var applicationName = ProcessInfo.processInfo.processName

    #if DEBUG
        let mainBundle = Bundle(path: "\(Bundle.main.bundlePath)/../../Sources/V-AMP Editor/Resources")!
    #else
        let mainBundle = Bundle.main
    #endif

    func localize(_ key: String) -> String {
       return mainBundle.localizedString(forKey: key, value: key, table: nil)
    }
    func localizeWithAppName(_ key: String) -> String {
       let menuTitle = mainBundle.localizedString(forKey: key, value: key, table: nil)
       return menuTitle.replacingOccurrences(of: "%s", with: applicationName)
    }

    override init(title: String) {
        super.init(title: "Main Menu")

        let appMenu = NSMenuItem()
        let servicesMenu = NSMenuItem(title: localize("Services"), action: nil, keyEquivalent: "")
        app.servicesMenu = NSMenu()
        servicesMenu.submenu = app.servicesMenu

        appMenu.submenu = NSMenu(title: "AppMenu")
        appMenu.submenu?.items = [
            NSMenuItem(title: localizeWithAppName("About"), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
            // NSMenuItem.separator(),
            // NSMenuItem(title: localize("Preferences"), action: nil, keyEquivalent: ","),
            NSMenuItem.separator(),
            servicesMenu,
            NSMenuItem.separator(),
            NSMenuItem(title: localizeWithAppName("Hide"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
            NSMenuItem(title: localize("Hide Others"), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h", modifier: [.command, .option]),
            NSMenuItem(title: localize("Show All"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: localizeWithAppName("Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]

        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: localize("File"))
        fileMenu.submenu?.items = [
            NSMenuItem(title: localize("Import"), action: #selector(ViewController.importSysEx(_:)), keyEquivalent: ""),
            NSMenuItem(title: localize("Export"), action: #selector(ViewController.exportSysEx(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: localize("Close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
        ]

        let editMenu = NSMenuItem()
        editMenu.submenu = NSMenu(title: localize("Edit"))
        editMenu.submenu?.items = [
            NSMenuItem(title: localize("Undo"), action: #selector(UndoManager.undo), keyEquivalent: "z"),
            NSMenuItem(title: localize("Redo"), action: #selector(UndoManager.redo), keyEquivalent: "Z"),
            NSMenuItem.separator(),
            NSMenuItem(title: localize("Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: localize("Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: localize("Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: localize("Delete"), action: nil, keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: localize("Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
        ]

        let windowsMenu = NSMenuItem()
        app.windowsMenu = NSMenu(title: localize("Window"))
        windowsMenu.submenu = app.windowsMenu
        windowsMenu.submenu?.items = [
            NSMenuItem(title: localize("Bring All to Front"), action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""),
        ]

        let helpMenu = NSMenuItem()
        app.helpMenu = NSMenu(title: localize("Help"))
        helpMenu.submenu = app.helpMenu

        items = [appMenu, fileMenu, editMenu, windowsMenu, helpMenu]
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

}

extension NSMenuItem {
    convenience init(title string: String, action selector: Selector?, keyEquivalent charCode: String, modifier: NSEvent.ModifierFlags = .command) {
        self.init(title: string, action: selector, keyEquivalent: charCode)
        self.keyEquivalentModifierMask = modifier
    }
}
