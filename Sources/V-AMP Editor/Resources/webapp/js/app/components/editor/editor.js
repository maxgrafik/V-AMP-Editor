/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

/* globals SwiftBridge */
define(["knockout"], function(ko) {
    "use strict";

    function Editor(params) {

        const self = this;

        self.isReady = false;

        ko.extenders.midiCC = function(target, ID) {
            const numeric = ko.pureComputed({
                read: target,
                write: function(newValue) {
                    const value = parseInt(newValue);
                    target(value);

                    if (self.isReady) {
                        // Send MIDI Control Change (ID, value)
                        if (ID === 50) {
                            const delayTimeHi = Math.floor(value/128);
                            const delayTimeLo = value - (delayTimeHi*128);
                            SwiftBridge.post("midiCC", { id: 50, val: delayTimeHi });
                            SwiftBridge.post("midiCC", { id: 51, val: delayTimeLo });
                        } else {
                            SwiftBridge.post("midiCC", { id: ID, val: value });
                        }
                    }
                }
            }).extend({ notify: "always" });
            numeric(target());
            return numeric;
        };


        /* ----- VIEW MODEL ----- */

        self.Patch = {
            Title : ko.observable(""),

            Amp     : ko.observable(32).extend({midiCC: 61}),
            Cabinet : ko.observable(0).extend({midiCC: 23}),
            Drive   : ko.observable(0).extend({midiCC: 26}),

            Gain     : ko.observable(0).extend({midiCC: 12}),
            Volume   : ko.observable(0).extend({midiCC: 16}),
            Bass     : ko.observable(0).extend({midiCC: 15}),
            Mid      : ko.observable(0).extend({midiCC: 14}),
            Treble   : ko.observable(0).extend({midiCC: 13}),
            Presence : ko.observable(0).extend({midiCC: 17}),

            PreFXType  : ko.observable(0).extend({midiCC: 44}),
            CompRatio  : ko.observable(0).extend({midiCC: 45}),
            CompAttack : ko.observable(0).extend({midiCC: 46}),
            WahSpeed   : ko.observable(0).extend({midiCC: 45}),
            WahDepth   : ko.observable(0).extend({midiCC: 46}),
            WahOffset  : ko.observable(0).extend({midiCC: 47}),
            WahFreq    : ko.observable(0).extend({midiCC: 48}),

            ModType     : ko.observable(0).extend({midiCC: 55}),
            ModSpeed    : ko.observable(0).extend({midiCC: 56}),
            ModDepth    : ko.observable(0).extend({midiCC: 57}),
            ModFeedback : ko.observable(64).extend({midiCC: 58}),
            ModMix      : ko.observable(0).extend({midiCC: 59}),

            ReverbType : ko.observable(0).extend({midiCC: 24}),
            ReverbMix  : ko.observable(0).extend({midiCC: 18}),

            DelayType     : ko.observable(0).extend({midiCC: 49}),
            DelayTime     : ko.observable(0).extend({midiCC: 50}),
            DelaySpread   : ko.observable(0).extend({midiCC: 52}),
            DelayFeedback : ko.observable(64).extend({midiCC: 53}),
            DelayMix      : ko.observable(0).extend({midiCC: 54}),

            NoiseGate   : ko.observable(0).extend({midiCC: 25}),
            WahPosition : ko.observable(0).extend({midiCC: 27}),

            FXMixAssign : ko.observable(0).extend({midiCC: 60}), // 20 = with defaults
            FXonoff     : ko.observable(0).extend({midiCC: 21}),
            ReverbSend  : ko.observable(0).extend({midiCC: 22})
        };
        self.Patch.dirtyFlag = new ko.dirtyFlag(self.Patch);

        self.Subscription = self.Patch.Title.subscribe(function(value) {
            const saveChars = value.replaceAll(/[^\x20-\x7F]/g, "");
            if (saveChars !== self.Patch.Title()) {
                self.Patch.Title(saveChars);
            }
        });


        /* ----- SELECTIONS ----- */

        self.Amps = ["AMERICAN BLUES", "MODERN CLASS A", "TWEED COMBO", "CLASSIC CLEAN", "BRIT. BLUES", "BRIT. CLASS A", "BRIT. CLASSIC", "BRIT. HI GAIN", "RECTIFIED HI GAIN", "MODERN HI GAIN", "FUZZ BOX", "ULTIMATE V-AMP", "DRIVE V-AMP", "CRUNCH V-AMP", "CLEAN V-AMP", "TUBE PREAMP", "AND DELUXE", "CUSTOM CLASS A", "SMALL COMBO", "BLACK TWIN", "AND CUSTOM", "NON TOP BOOST", "CLASSIC 50 W", "BRIT. CLASS A 15 W", "RECTIFIED HEAD", "SAVAGE BEAST", "CUSTOM HI GAIN", "ULTIMATE PLUS", "CALIF. DRIVE", "CUSTOM DRIVE", "CALIF. CLEAN", "CUSTOM CLEAN", "BYPASS"];
        self.Cabs = ["BYPASS", "1 x 8\" VINTAGE TWEED", "4 x 10\" VINTAGE BASS", "4 x 10\" V-AMP CUSTOM", "1 x 12\" MID COMBO", "1 x 12\" BLACKFACE", "1 x 12\" BRIT ’60", "1 x 12\" DELUXE ’52", "2 x 12\" TWIN COMBO", "2 x 12\" US CLASS A", "2 x 12\" V-AMP CUSTOM", "2 x 12\" BRIT ’67", "4 x 12\" VINTAGE 30", "4 x 12\" STANDARD ’78", "4 x 12\" OFF AXIS", "4 x 12\" V-AMP CUSTOM"];
        self.FXTypes = ["ECHO", "DELAY", "PING PONG", "PHASER + DELAY", "FLANGER + DELAY 1", "FLANGER + DELAY 2", "CHORUS + DELAY 1", "CHORUS + DELAY 2", "CHORUS + COMPRESSOR", "COMPRESSOR", "AUTO WAH", "PHASER", "CHORUS", "FLANGER", "TREMOLO", "ROTARY"];
        self.FXHints = [["Mix", "Feedback", "Delay Time"], ["Mix", "Feedback", "Delay Time"], ["Mix", "Feedback", "Delay Time"], ["Delay Mix", "Phaser Mix", "Delay Time"], ["Delay Mix", "Flanger Mix", "Delay Time"], ["Delay Mix", "Flanger Mix", "Delay Time"], ["Delay Mix", "Chorus Mix", "Delay Time"], ["Delay Mix", "Chorus Mix", "Delay Time"], ["Ratio", "Chorus Mix", "Mod Speed"], ["Ratio", "Attack", "–"], ["Depth", "Speed", "–"], ["Mix", "Feedback", "Mod Speed"], ["Mix", "Depth", "Mod Speed"], ["Mix", "Feedback", "Mod Speed"], ["Mix", "–", "Mod Speed"], ["Mix", "Depth", "Mod Speed"]];
        self.PreFX = ["OFF", "COMPRESSOR", "AUTO WAH"];
        self.ModTypes = ["ROTARY", "PHASER", "TREMELO", "CHORUS 1 (Mono)", "CHORUS 2 (Stereo)", "FLANGER 1 (Mono)", "FLANGER 2 (Stereo)"];
        self.DelayTypes = ["DELAY", "ECHO", "PING PONG"];
        self.ReverbTypes = ["TINY ROOM", "SMALL ROOM", "MEDIUM ROOM", "LARGE ROOM", "ULTRA ROOM", "SMALL SPRING", "MEDIUM SPRING", "SHORT AMBIENCE", "LONG AMBIENCE"];

        self.Select = function(arr) {
            return ko.pureComputed(function() {
                return ko.utils.arrayMap(arr, function(item) {
                    return { id: arr.indexOf(item), name: item };
                });
            }, self);
        };

        self.FXHint = function(index) {
            return ko.pureComputed(function() {
                return self.FXHints[self.Patch.FXMixAssign()][index];
            });
        };


        /* ----- REGISTER COMPONENTS ----- */

        if (!ko.components.isRegistered("slider")) {
            ko.components.register("slider", { require: "components/slider/slider" });
        }
        if (!ko.components.isRegistered("switch")) {
            ko.components.register("switch", { require: "components/switch/switch" });
        }


        /* ----- REGISTER DIALOGS ----- */

        if (!ko.components.isRegistered("EditValue")) {
            ko.components.register("EditValue", {
                viewModel: { require: "dialog/sheet" },
                template: { require: "text!dialog/editvalue.html" }
            });
        }

        if (!ko.components.isRegistered("SavePatch")) {
            ko.components.register("SavePatch", {
                viewModel: { require: "dialog/sheet" },
                template: { require: "text!dialog/save.html" }
            });
        }


        /* ----- HELPERS ----- */

        self.FXTab = ko.observable("0");

        self.rawValue = ko.observable(null);
        self.SavePatchTo = ko.observable(null);

        self.editValue = function(data, event) {
            let slider = event.target.closest("figcaption");
            if (slider) {
                const vm = ko.dataFor(slider);
                self.rawValue({
                    value: vm.Value,
                    min: vm.Min,
                    max: vm.Max
                });
            }
        };

        self.setValue = function(oldVal, newVal) {
            let value = parseInt(newVal.value());
            if (isNaN(value)) {
                return;
            }
            if (value < newVal.min() || value > newVal.max()) {
                return;
            }
            oldVal.value(value);
        };

        self.confirmSave = function() {
            self.SavePatchTo(params.buffer().index);
        };

        self.savePatch = function(oldIndex, newIndex) {
            const index = ko.unwrap(newIndex);
            const patch = self.writePatch();

            params.presets()[index].name(self.Patch.Title());
            params.buffer().index = index;
            self.Patch.dirtyFlag.setClean();

            SwiftBridge.post("setPreset", { index: index, data: patch });
        };

        self.confirmClose = function() {
            if (self.Patch.dirtyFlag.isDirty()) {
                SwiftBridge.alert({
                    msgID: "ConfirmClose",
                    title: "Unsaved changes",
                    text: "Are you sure you want to close the editor?",
                    style: "warning",
                    buttons: [
                        { title: "Cancel", destructive: false },
                        { title: "Close", destructive: false }
                    ]
                });
            } else {
                self.closeEditor();
            }
        };

        SwiftBridge.on("ConfirmClose", (buttonClicked) => {
            if (buttonClicked === 2 ) {
                self.closeEditor();
            }
        });


        self.closeEditor = function() {
            SwiftBridge.post("clearBuffer", null);
            params.buffer(null);
        };


        /* ----- READ PATCH ----- */

        if (params.buffer() !== null) {
            self.readPatch(params.buffer().data);
            self.isReady = true;
        }
    }

    Editor.prototype.readPatch = function(data) {
        const self = this;

        self.Patch.Gain(data.charCodeAt(0));
        self.Patch.Treble(data.charCodeAt(1));
        self.Patch.Mid(data.charCodeAt(2));
        self.Patch.Bass(data.charCodeAt(3));
        self.Patch.Volume(data.charCodeAt(4));
        self.Patch.Presence(data.charCodeAt(5));
        self.Patch.ReverbMix(data.charCodeAt(6));
        self.Patch.Amp(data.charCodeAt(7));

        self.Patch.FXMixAssign(data.charCodeAt(8));
        self.Patch.FXonoff(data.charCodeAt(9));
        self.Patch.ReverbSend(data.charCodeAt(10));

        self.Patch.Cabinet(data.charCodeAt(11));
        self.Patch.ReverbType(data.charCodeAt(12));
        self.Patch.NoiseGate(data.charCodeAt(13));
        self.Patch.Drive(data.charCodeAt(14));
        self.Patch.WahPosition(data.charCodeAt(15));

        self.Patch.PreFXType(data.charCodeAt(16));
        self.Patch.CompRatio(data.charCodeAt(17));
        self.Patch.CompAttack(data.charCodeAt(18));
        self.Patch.WahSpeed(data.charCodeAt(17));
        self.Patch.WahDepth(data.charCodeAt(18));
        self.Patch.WahOffset(data.charCodeAt(19));
        self.Patch.WahFreq(data.charCodeAt(20));

        self.Patch.DelayType(data.charCodeAt(21));

        let delayTimeHi = data.charCodeAt(22);
        let delayTimeLo = data.charCodeAt(23);
        self.Patch.DelayTime((delayTimeHi*128)+delayTimeLo);
        self.Patch.DelaySpread(data.charCodeAt(24));
        self.Patch.DelayFeedback(data.charCodeAt(25));
        self.Patch.DelayMix(data.charCodeAt(26));

        self.Patch.ModType(data.charCodeAt(27));
        self.Patch.ModSpeed(data.charCodeAt(28));
        self.Patch.ModDepth(data.charCodeAt(29));
        self.Patch.ModFeedback(data.charCodeAt(30));
        self.Patch.ModMix(data.charCodeAt(31));

        self.Patch.Title(data.substring(32).trimEnd());

        self.Patch.dirtyFlag.setClean();
    };

    Editor.prototype.writePatch = function() {
        const self = this;

        let preFX = [0, 0, 0, 0];
        if (self.Patch.PreFXType() === 1) {
            preFX[0] = self.Patch.CompRatio();
            preFX[1] = self.Patch.CompAttack();

        } else if (self.Patch.PreFXType() === 2) {
            preFX[0] = self.Patch.WahSpeed();
            preFX[1] = self.Patch.WahDepth();
            preFX[2] = self.Patch.WahOffset();
            preFX[3] = self.Patch.WahFreq();
        }

        const delayTime = self.Patch.DelayTime();
        const delayTimeHi = Math.floor(delayTime/128);
        const delayTimeLo = delayTime - (delayTimeHi*128);

        let title = self.Patch.Title()
            .replaceAll(/[^\x20-\x7F]/g, "")
            .substring(0, 16)
            .padEnd(16, " ");

        return String.fromCharCode(
            self.Patch.Gain(),
            self.Patch.Treble(),
            self.Patch.Mid(),
            self.Patch.Bass(),
            self.Patch.Volume(),
            self.Patch.Presence(),
            self.Patch.ReverbMix(),
            self.Patch.Amp(),
            self.Patch.FXMixAssign(),
            self.Patch.FXonoff(),
            self.Patch.ReverbSend(),
            self.Patch.Cabinet(),
            self.Patch.ReverbType(),
            self.Patch.NoiseGate(),
            self.Patch.Drive(),
            self.Patch.WahPosition(),
            self.Patch.PreFXType(),
            preFX[0],
            preFX[1],
            preFX[2],
            preFX[3],
            self.Patch.DelayType(),
            delayTimeHi,
            delayTimeLo,
            self.Patch.DelaySpread(),
            self.Patch.DelayFeedback(),
            self.Patch.DelayMix(),
            self.Patch.ModType(),
            self.Patch.ModSpeed(),
            self.Patch.ModDepth(),
            self.Patch.ModFeedback(),
            self.Patch.ModMix(),
        ) + title;
    };

    Editor.prototype.dispose = function() {
        const self = this;
        self.Subscription.dispose();
    };

    return {
        viewModel: Editor,
        template: { require: "text!components/editor/editor.html" }
    };

});
