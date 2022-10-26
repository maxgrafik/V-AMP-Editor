/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

/* globals SwiftBridge */
/* eslint-disable-next-line no-unused-vars */
define(["knockout", "knockout-bindings"], function(ko, koBindings) {
    "use strict";

    function App() {

        const self = this;

        /* ----- VIEW MODEL ----- */

        self.Devices = ko.observableArray([]);
        self.DeviceIndex = ko.observable(null);
        self.isConnected = ko.observable(false);

        self.Presets = ko.observableArray([]);
        self.Buffer  = ko.observable(null);

        self.Preset = function(index, name) {
            this.index = ko.observable(index);
            this.name  = ko.observable(name),
            this.patch = ko.pureComputed(function() {
                const bank = Math.floor(this.index()/5) + 1;
                const slot = this.index() % 5;
                return bank + ["A", "B", "C", "D", "E"][slot];
            }, this);
        };


        /* ----- EVENTS ----- */

        SwiftBridge.on("Device", (device) => {
            if (!self.isConnected()) {
                self.Devices.push({
                    index: ko.observable(device.id),
                    name: ko.observable(device.name)
                });
            }
        });

        SwiftBridge.on("Presets", (presets) => {
            if (self.isConnected()) {
                if (Array.isArray(presets)) {
                    self.Presets([]);
                    self.Buffer(null);
                    presets.forEach((data, index) => {
                        self.Presets.push(new self.Preset(index, data));
                    });
                }
            }
        });

        SwiftBridge.on("Buffer", (data) => {
            if (self.isConnected()) {
                self.Buffer(null);
                self.Buffer({
                    index: 127,
                    data: data
                });
            }
        });


        /* ----- ACTIONS ----- */

        self.connect = function() {
            SwiftBridge.post("connect", self.DeviceIndex());
            self.isConnected(true);
        };

        self.canConnect = ko.pureComputed(function() {
            return self.Devices().length > 0 && self.DeviceIndex() !== null;
        });

        self.editPreset = function(preset) {
            SwiftBridge.post("getPreset", preset.index());
        };


        /* ----- REGISTER COMPONENTS ----- */

        ko.components.register("Editor", { require: "components/editor/editor" });


        /* ----- INIT ----- */

        SwiftBridge.post("ready", null);

    }

    App.prototype.dispose = function() {};

    return {
        viewModel: App,
        template: { require: "text!app/app.html" }
    };

});
