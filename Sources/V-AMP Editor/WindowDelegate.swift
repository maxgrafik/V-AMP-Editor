//
// WindowDelegate.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

class WindowDelegate: NSObject, NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}
