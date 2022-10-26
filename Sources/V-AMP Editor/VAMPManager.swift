//
// VAMPManager.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit

class VAMPManager {

    var Presets: [Data] = []
    var Buffer: Data? = nil

    private var fileHandler = FileHandler()

    func importPreset(_ completionHandler: @escaping ([Data]) -> Void) {
        self.fileHandler.read({ data in

            self.validate(data, { (preset, error) in

                guard preset != nil else {
                    self.alert(error ?? "")
                    return
                }

                if preset!.count > 1 && !self.confirmOverwrite() {
                    return
                }

                completionHandler(preset!)
            })
        })
    }

    func exportPreset() {

        var data = Data()
        var fileName: String
        var exportAll: Bool? = true

        if Buffer != nil {
            exportAll = self.confirmExport()
        }

        guard exportAll != nil else { return }

        data.append(contentsOf: [0xF0, 0x00, 0x20, 0x32, 0x7F, 0x11])

        if exportAll! {

            fileName = "VAMP Presets"

            data.append(0x21)
            data.append(0x7D)
            data.append(0x30)
            for index in 0..<125 {
                data.append(contentsOf: Presets[index])
            }
        } else {

            fileName = getPresetName(Buffer!) ?? "Untitled"

            data.append(0x20)
            data.append(0x7F)
            data.append(0x30)
            data.append(Buffer!)
        }

        data.append(0xF7)

        self.fileHandler.write(data, as: fileName)
    }

    func validate(_ data: Data, _ completionHandler: @escaping ([Data]?, String?) -> Void) {

        if data.isEmpty || data.count < 9 {
            completionHandler(nil, "Invalid data")
            return
        }

        // SysEx Marker (0xF0)
        if data[0] != 0xF0 {
            completionHandler(nil, "No SysEx data")
            return
        }

        // CompanyID (0x002032)
        if data[1] != 0x00 && data[2] != 0x20 && data[3] != 0x32 {
            completionHandler(nil, "Not for Behringer")
            return
        }

        // DeviceID (0x7F)
        // data[4]

        // ModelID (0x11)
        if data[5] != 0x11 {
            completionHandler(nil, "Not for V-AMP")
            return
        }

        // Command
        // 0x20 = Single Preset
        // 0x21 = All Presets
        if data[6] != 0x20 && data[6] != 0x21 {
            completionHandler(nil, "Invalid SysEx command")
            return
        }

        // PresetNo or Preset count (0x7D)
        if data[6] == 0x21 && data[7] != 0x7D {
            completionHandler(nil, "Invalid preset count")
            return
        }

        // Preset length (0x30)
        if data[8] != 0x30 {
            completionHandler(nil, "Invalid preset length")
            return
        }

        let presetCount = (data[6] == 0x21) ? 125 : 1
        let totalLength = presetCount * 0x30

        if data.count != totalLength + 10 {
            completionHandler(nil, "Invalid data length")
            return
        }

        // SysEx Marker (0xF7)
        if data.last != 0xF7 {
            completionHandler(nil, "Invalid SysEx marker")
            return
        }

        if presetCount > 1 {
            var presets: [Data] = []
            for presetNo in 0..<presetCount {
                let firstIndex = 9 + (presetNo * 0x30)
                let lastIndex = firstIndex + 0x30
                let preset = data.subdata(in: firstIndex..<lastIndex)
                presets.append(preset)
            }
            completionHandler(presets, nil)

        } else {
            completionHandler([data.subdata(in: 9..<(9+0x30))], nil)
        }
    }

    func getPreset(_ index: Int) -> Data? {
        if index < self.Presets.count {
            return self.Presets[index]
        }
        return nil
    }

    func setPreset(_ index: Int, data: Data) {
        if index < self.Presets.count {
            self.Presets[index] = data
        } else if index == 127 {
            self.Buffer = data
        }
    }

    func getPresetName(_ preset: Data) -> String? {

        let subdata = preset.subdata(in: 32..<48)

        guard let name = String(data: subdata, encoding: .ascii) else {
            return nil
        }

        return name
    }

    func clearBuffer() {
        self.Buffer = nil
    }

    func alert(_ msg: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Error reading data"
        alert.informativeText = msg
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func confirmExport() -> Bool? {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Export Preset"
        alert.informativeText = "Do you want to export only the current preset or all presets?"
        alert.addButton(withTitle: "Export current preset")
        alert.addButton(withTitle: "Export all presets")
        alert.addButton(withTitle: "Cancel")

        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            return false
        case .alertSecondButtonReturn:
            return true
        case .alertThirdButtonReturn:
            return nil
        default:
            return nil
        }
    }

    func confirmOverwrite() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Import Presets"
        alert.informativeText = "This file contains multiple presets. Do you want to overwrite all current V-AMP presets? This action cannot be undone."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Import")

        if #available(macOS 11.0, *) {
            alert.buttons.last?.hasDestructiveAction = true
        }

        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            return false
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

}
