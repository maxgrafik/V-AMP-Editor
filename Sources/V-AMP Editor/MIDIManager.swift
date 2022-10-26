//
// MIDIManager.swift
// V-AMP Editor
//
// Copyright 2022 Hendrik Meinl | maxgrafik.de
//
// This class uses all kinds of deprecated symbols,
// but I can't get the recommended ones to work :P
//


import AppKit
import CoreMIDI

class MIDIManager {

    private var midiClient = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var inputPort = MIDIPortRef()

    private var VAMPDeviceID = UInt8(0x7F) // Broadcast
    private var VAMPMIDIchannel = UInt8(0)
    private var SysExMessage = Data()

    var isAvailable = false
    var LastError: String? = nil

    init() {

        let notifyBlock:MIDINotifyBlock = self.MyMIDINotifyBlock
        let readBlock:MIDIReadBlock = self.MyMIDIReadBlock

        var status = noErr

        status = MIDIClientCreateWithBlock("de.maxgrafik.vedit" as CFString, &midiClient, notifyBlock)
        if status != noErr {
            LastError = "Error creating MIDI client"
            return
        }

        if status == noErr {

            status = MIDIInputPortCreateWithBlock(midiClient, "de.maxgrafik.vedit.MIDIInput" as CFString, &inputPort, readBlock)
            if status != noErr {
                LastError = "Error creating input port"
                return
            }

            status = MIDIOutputPortCreate(midiClient, "de.maxgrafik.vedit.MIDIOutput" as CFString, &outputPort)
            if status != noErr {
                LastError = "Error creating output port"
                return
            }

            let sourceCount = MIDIGetNumberOfSources()
            for srcIndex in 0 ..< sourceCount {
                let midiEndPoint = MIDIGetSource(srcIndex)
                status = MIDIPortConnectSource(inputPort, midiEndPoint, nil)
                if status != noErr {
                    LastError = "Error connecting source"
                    return
                }
            }
        }

        self.isAvailable = true
        print("MIDI setup OK")
    }

    func getDevices() {

        var packet:MIDIPacket = MIDIPacket()

        packet.timeStamp = 0
        packet.length = 8
        packet.data.0 = 0xF0
        packet.data.1 = 0x00
        packet.data.2 = 0x20
        packet.data.3 = 0x32
        packet.data.4 = VAMPDeviceID
        packet.data.5 = 0x11 // V-AMP 2/PRO, V-AMPIRE
        packet.data.6 = 0x01 // Identify device
        packet.data.7 = 0xF7

        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet)

        // Send to all destinations since SysEx has no MIDI channel
        let count: Int = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i)
            if (endpoint != 0) {
                MIDISend(outputPort, endpoint, &packetList);
            }
        }
    }

    func getPresets(_ deviceID: UInt8) {

        self.VAMPDeviceID = deviceID

        var packet:MIDIPacket = MIDIPacket()

        packet.timeStamp = 0
        packet.length = 8
        packet.data.0 = 0xF0
        packet.data.1 = 0x00
        packet.data.2 = 0x20
        packet.data.3 = 0x32
        packet.data.4 = VAMPDeviceID
        packet.data.5 = 0x11 // V-AMP 2/PRO, V-AMPIRE
        packet.data.6 = 0x61 // Request all presets
        packet.data.7 = 0xF7

        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet)

        // Send to all destinations since SysEx has no MIDI channel
        let count: Int = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i)
            if (endpoint != 0) {
                MIDISend(outputPort, endpoint, &packetList);
            }
        }
    }

    func writeSinglePreset(_ presetNo: UInt8, data: Data) {

        var preset: [UInt8] = []
        var chunks: [[UInt8]] = []

        preset.append(0xF0)
        preset.append(0x00)
        preset.append(0x20)
        preset.append(0x32)
        preset.append(VAMPDeviceID)
        preset.append(0x11) // V-AMP 2/PRO, V-AMPIRE
        preset.append(0x20) // Write single preset
        preset.append(presetNo)
        preset.append(0x30) // Preset length
        for i in 0..<data.count {
            preset.append(data[i])
        }
        preset.append(0xF7)

        while(preset.count > 0) {
            let endIndex = min(preset.count, 32)
            let chunk = Array(preset[0..<endIndex])
            chunks.append(chunk)
            preset.removeSubrange(0..<endIndex)
        }

        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)

        for chunk in chunks {
            packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, chunk.count, chunk)
        }

        // Send to all destinations since SysEx has no MIDI channel
        let count: Int = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i)
            if (endpoint != 0) {
                MIDISend(outputPort, endpoint, &packetList);
            }
        }
    }

    func writeAllPresets(data: [Data]) {
        for (index, preset) in data.enumerated() {
            let presetNo = UInt8(index)
            self.writeSinglePreset(presetNo, data: preset)
        }
    }

    func sendControlChange(_ id: UInt8, _ val: UInt8) {

        var packet:MIDIPacket = MIDIPacket()

        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = 0xB0 + self.VAMPMIDIchannel
        packet.data.1 = id
        packet.data.2 = val

        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet)

        // Send to all destinations
        // No idea how to retrieve the V-AMP's MIDI channel and destination
        let count: Int = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i)
            if (endpoint != 0) {
                MIDISend(outputPort, endpoint, &packetList);
            }
        }
    }

    func MyMIDINotifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
        _ = midiNotification.pointee
        //print("MIDINotification")
    }

    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Void {

        let mPacketList: MIDIPacketList = packetList.pointee
        var mPacket: MIDIPacket = mPacketList.packet

        for _ in 1...mPacketList.numPackets {
            let bytes = Mirror(reflecting: mPacket.data).children

            var mPacketLength = mPacket.length
            for (_, attr) in bytes.enumerated() {
                let byte = attr.value as! UInt8
                if byte == 0xF0 {
                    // Start of SysEx Message
                    self.SysExMessage.removeAll(keepingCapacity: false)
                    self.SysExMessage.append(byte)

                } else if byte == 0xF7 && self.SysExMessage.isEmpty == false {
                    // End of SysEx Message
                    self.SysExMessage.append(byte)
                    self.handleSysExMessage(self.SysExMessage)
                    self.SysExMessage.removeAll(keepingCapacity: false)

                } else {
                    self.SysExMessage.append(byte)
                }

                mPacketLength -= 1
                if (mPacketLength <= 0) {
                    break
                }
            }
            mPacket = MIDIPacketNext(&mPacket).pointee
        }
    }

    func handleSysExMessage(_ data: Data) {

        if data.count < 6 {
            return // too short
        }

        if data[0] != 0xF0 {
            return // no sysex
        }

        // Behringer CompanyID (0x00 0x20 0x32)
        if data[1] != 0x00 && data[2] != 0x20 && data[3] != 0x32 {
            return // not Behringer
        }

        // V-AMP2/PRO ModelID (0x11)
        if data[5] != 0x11 {
            return // not V-AMP
        }

        switch data[6] {

        case 0x02: // Identify Device

            var name = Data()
            for i in 7..<data.endIndex {
                if data[i] != 0xF7 {
                    name.append(data[i])
                }
            }

            guard let deviceName = String(data: name, encoding: .ascii) else {
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "didReceiveDeviceName"),
                object: (id: data[4], name: deviceName)
            )
            break

        case 0x21: // All Presets

            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "didReceivePresets"),
                object: data
            )
            break

        default:
            print("Unhandled command \(data[6])")
            break
        }
    }

}
