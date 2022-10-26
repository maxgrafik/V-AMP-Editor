//
// FileHandler.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

class FileHandler {

    func read(_ completionHandler: @escaping (Data) -> Void) {

        let openPanel = NSOpenPanel()

        if #available(macOS 11.0, *) {
            let contentType = UTType(filenameExtension: "syx", conformingTo: .data)
            openPanel.allowedContentTypes = [contentType!]
        } else {
            openPanel.allowedFileTypes = ["syx"]
        }

        openPanel.canChooseFiles = true
        openPanel.begin { (result) in
            if result == NSApplication.ModalResponse.OK {

                guard let url = openPanel.url else { return }

                do {
                    let data = try Data(contentsOf: url)
                    completionHandler(data)
                } catch (let error) {
                    self.alert("Cannot read file", "\(error.localizedDescription)")
                }
            }
        }
    }

    func write(_ data: Data, as fileName: String) {

        let savePanel = NSSavePanel()

        if #available(macOS 11.0, *) {
            let contentType = UTType(filenameExtension: "syx", conformingTo: .data)
            savePanel.allowedContentTypes = [contentType!]
        } else {
            savePanel.allowedFileTypes = ["syx"]
        }

        savePanel.nameFieldStringValue = fileName.trimmingCharacters(in: .whitespaces) + ".syx"
        savePanel.begin { (result) in
            if result == NSApplication.ModalResponse.OK {

                guard let url = savePanel.url else { return }

                do {
                    try data.write(to: url, options: [.atomic])
                } catch (let error) {
                    self.alert("Cannot write file", "\(error.localizedDescription)")
                }
            }
        }
    }

    func alert(_ messageText: String, _ informativeText: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}
