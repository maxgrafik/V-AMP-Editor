//
// main.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

let app = NSApplication.shared

let appMainMenu = AppMenu()
app.mainMenu = appMainMenu

let appDelegate = AppDelegate()
app.delegate = appDelegate

app.run()
