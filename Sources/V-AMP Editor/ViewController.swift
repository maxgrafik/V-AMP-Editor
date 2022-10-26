//
// ViewController.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//

import AppKit
import WebKit

class ViewController: NSViewController, WKUIDelegate {

    private var webView: WKWebView?
    private var webConfiguration: WKWebViewConfiguration?

    private var VAMP: VAMPManager?
    private var MIDI: MIDIManager?

    override func loadView() {

        webConfiguration = WKWebViewConfiguration()

        // XMLHttpRequests for local resources are considered CORS and therefore will fail
        // https://stackoverflow.com/questions/48787945/wkwebview-xmlhttprequest-failed-to-load-resource
        webConfiguration?.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Install SwiftBridge MessageHandler
        webConfiguration?.userContentController.add(self, name: "SwiftBridge")

        // Enable Web Inspector
        // https://stackoverflow.com/questions/25200116/how-to-show-the-inspector-within-your-wkwebview-based-desktop-app
        #if DEBUG
            webConfiguration?.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        // Create WKWebView with config
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 280), configuration: webConfiguration!)
        webView?.uiDelegate = self

        view = webView!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Bundle.main.resourceURL
        #if DEBUG
            let mainBundle = Bundle(path: "\(Bundle.main.bundlePath)/../../Sources/V-AMP Editor/Resources")!
        #else
            let mainBundle = Bundle.main
        #endif

        // Load SwiftBridge.js from Resources ...
        guard let scriptPath = mainBundle.path(forResource: "SwiftBridge", ofType: "js", inDirectory: "SwiftBridge"),
              let scriptSource = try? String(contentsOfFile: scriptPath) else { return }

        // ... and inject
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webConfiguration?.userContentController.addUserScript(userScript)

        // Load local index.html
        if let fileURL = mainBundle.url(forResource: "index", withExtension: "html", subdirectory: "webapp") {
            webView?.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        }

        self.VAMP = VAMPManager()
        self.MIDI = MIDIManager()

        NotificationCenter.default.addObserver(self,
           selector: #selector(didReceiveDeviceName(notification:)),
           name: NSNotification.Name(rawValue: "didReceiveDeviceName"),
           object: nil)

        NotificationCenter.default.addObserver(self,
           selector: #selector(didReceivePresets(notification:)),
           name: NSNotification.Name(rawValue: "didReceivePresets"),
           object: nil)
    }

    override func viewDidDisappear() {
        webConfiguration?.userContentController.removeAllUserScripts()
        webConfiguration?.userContentController.removeScriptMessageHandler(forName: "SwiftBridge")

        NotificationCenter.default.removeObserver(self)

        self.VAMP = nil
        self.MIDI = nil
    }

    @objc func didReceiveDeviceName(notification: NSNotification) {

        guard let device = notification.object as? (id: UInt8, name: String) else {
            return
        }

        struct Device: Codable {
            var id: UInt8
            var name: String
        }

        let payload = Device(id: device.id, name: device.name)

        self.dispatchEvent("Device", payload: payload)
    }

    @objc func didReceivePresets(notification: NSNotification) {

        guard let data = notification.object as? Data else {
            return
        }

        self.VAMP?.validate(data, { (presets, error) in

            if presets == nil {
                print(error!)
                return
            }

            if presets!.count > 1 {
                var presetNames: [String?] = []

                self.VAMP?.Presets = []
                for presetNo in 0..<presets!.count {

                    let preset = presets![presetNo]
                    self.VAMP?.Presets.append(preset)

                    let presetName = self.VAMP?.getPresetName(preset)
                    presetNames.append(presetName)
                }
                self.dispatchEvent("Presets", payload: presetNames)
            }
        })
    }

    @objc func importSysEx(_ sender: NSMenuItem) {
        self.VAMP?.importPreset({ preset in

            if preset.count == 1 {
                self.VAMP?.setPreset(127, data: preset[0])
                self.MIDI?.writeSinglePreset(0x7F, data: preset[0])

                let buffer = String(data: preset[0], encoding: .ascii)
                self.dispatchEvent("Buffer", payload: buffer)

            } else {
                var presets: [Data] = []
                for presetNo in 0..<preset.count {
                    presets.append(preset[presetNo])
                }

                self.VAMP?.Presets = presets
                self.MIDI?.writeAllPresets(data: presets)

                var presetNames: [String?] = []
                for p in presets {
                    presetNames.append(self.VAMP!.getPresetName(p))
                }
                self.dispatchEvent("Presets", payload: presetNames)
            }
        })
    }

    @objc func exportSysEx(_ sender: NSMenuItem) {
        self.VAMP?.exportPreset()
    }

    func dispatchEvent(_ name: String, payload: Encodable) {
        guard let json = try? JSONEncoder().encode(payload),
            let jsonString = String(data: json, encoding: .utf8) else {
                return
        }

        let script = """
        window.dispatchEvent(
            new CustomEvent(
                'SwiftBridgeEvent', {
                    detail: {'event': '\(name)', 'data':\(jsonString)}
                }
            ))
        """

        webView?.evaluateJavaScript(script, completionHandler: nil)
    }

}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "SwiftBridge" {
            guard let dict = message.body as? [String : AnyObject],
                let eventType = dict["event"] as? String,
                let eventData = dict["data"] else {
                    return
            }

            switch eventType {
            case "ready":
                // WebView ready ... find V-AMPs in MIDI devices
                self.MIDI?.getDevices()
                break

            case "connect":
                // Connect & load presets from V-AMP
                let deviceID = eventData as! UInt8
                self.MIDI?.getPresets(deviceID)
                break

            case "getPreset":
                guard let preset = self.VAMP?.getPreset(eventData as! Int) else {
                    return
                }
                self.VAMP?.setPreset(127, data: preset) // write to Buffer
                self.MIDI?.writeSinglePreset(0x7F, data: preset) // write to Buffer
                self.dispatchEvent("Buffer", payload: String(data: preset, encoding: .ascii))
                break

            case "setPreset":
                guard let preset = eventData as? [String : AnyObject],
                    let index = preset["index"] as? Int,
                    let data = preset["data"] as? String else {
                        return
                }
                let presetData = Data(data.utf8)
                self.VAMP?.setPreset(index, data: presetData)
                self.MIDI?.writeSinglePreset(UInt8(index), data: presetData)
                break

            case "clearBuffer":
                self.VAMP?.clearBuffer()
                break

            case "midiCC":
                guard let midiCC = eventData as? [String : UInt8],
                    let id = midiCC["id"],
                    let val = midiCC["val"] else {
                        return
                }
                self.MIDI?.sendControlChange(id, val)
                break

            case "Alert":
                guard let alertConfig = eventData as? [String : AnyObject],
                    let alertID = alertConfig["msgID"] as? String,
                    let alertStyle = alertConfig["style"] as? String,
                    let alertTitle = alertConfig["title"] as? String,
                    let alertText = alertConfig["text"] as? String,
                    let alertButtons = alertConfig["buttons"] as? [[String : AnyObject]] else {
                        return
                }

                let alert = NSAlert()
                alert.alertStyle = (alertStyle == "warning") ? .warning : .informational
                alert.messageText = alertTitle
                alert.informativeText = alertText
                for alertButton in alertButtons {
                    guard let buttonTitle = alertButton["title"] as? String,
                        let buttonAction = alertButton["destructive"] as? Bool else {
                            return
                    }
                    alert.addButton(withTitle: buttonTitle)

                    if #available(macOS 11.0, *) {
                        alert.buttons.last?.hasDestructiveAction = buttonAction
                    }
                }

                let result = alert.runModal()
                switch result {
                case .alertFirstButtonReturn:
                    self.dispatchEvent(alertID, payload: 1)
                case .alertSecondButtonReturn:
                    self.dispatchEvent(alertID, payload: 2)
                case .alertThirdButtonReturn:
                    self.dispatchEvent(alertID, payload: 3)
                default:
                    self.dispatchEvent(alertID, payload: 0)
                }
                break

            default:
                #if DEBUG
                    print("Unknown script message ", dict)
                #endif
            }
        }
    }
}

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard self.VAMP != nil else {
            return false
        }
        return self.VAMP!.Presets.count > 0
    }
}
