//
// AppDelegate.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow?
    private var windowDelegate = WindowDelegate()

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let contentViewController = ViewController()
        window = NSWindow(contentViewController: contentViewController)

        window?.delegate = windowDelegate

        window?.styleMask = [.miniaturizable, .closable, .titled]
        window?.title = "V-AMP Editor"

        window?.setFrameAutosaveName("V-AMP Editor")
        window?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
