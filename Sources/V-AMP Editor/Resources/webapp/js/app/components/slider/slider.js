/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

define(["knockout"], function(ko) {
    "use strict";

    function Slider(params) {

        const self = this;

        self.Min   = ko.observable(0);
        self.Max   = ko.observable(0);
        self.Value = params.value;
        self.Label = ko.observable(params.label);

        self.LEDSlider = ko.observable(true);
        self.Disabled  = params.disabled;

        self.NoiseGate = ko.pureComputed(function() {
            const index = self.Value();
            return ["off", "-90dB", "-87dB", "-84dB", "-81dB", "-78dB", "-75dB", "-72dB", "-69dB", "-66dB", "-63dB", "-60dB", "-57dB", "-54dB", "-51dB", "-48dB"][index];
        }, self);

        self.CompRatio = ko.pureComputed(function() {
            const index = Math.floor(self.Value()/22);
            return ["1.2:1", "1.4:1", "2:1", "2.5:1", "3:1", "4.5:1"][index];
        }, self);

        self.CompAttack = ko.pureComputed(function() {
            const ms = Math.floor(Math.pow(self.Value(),2)/256)+1;
            return ms + "ms";
        }, self);

        self.Speed = ko.pureComputed(function() {
            if (params.modType && params.modType() < 2) {
                let Hz = Math.pow(self.Value(),2) * 0.00059;
                Hz = Math.round(Hz*100)/100;
                return Hz + "Hz";

            } else if (params.modType && params.modType() === 2) {
                let Hz = Math.pow(self.Value(),2) * 0.00062;
                Hz = Math.round(Hz*100)/100;
                return Hz + "Hz";

            } else if (params.modType && params.modType() > 2) {
                let Hz = Math.pow(self.Value(),2) * 0.00031;
                Hz = Math.round(Hz*100)/100;
                return Hz + "Hz";

            } else {
                const index = Math.floor(self.Value()/13);
                return ["0ms", "20ms", "50ms", "100ms", "200ms", "300ms", "400ms", "500ms", "750ms", "1000ms"][index];
            }
        }, self);

        self.DelayTime = ko.pureComputed(function() {
            let ms = self.Value() * 128 / 1000;
            ms = Math.round(ms);
            return ms + "ms";
        }, self);

        switch(params.label) {
        case "NOISE GATE":
            self.Min(0);
            self.Max(15);
            self.DisplayValue = self.NoiseGate;
            self.LEDSlider(false);
            break;
        case "RATIO":
            self.Min(0);
            self.Max(127);
            self.DisplayValue = self.CompRatio;
            self.LEDSlider(false);
            break;
        case "ATTACK":
            self.Min(0);
            self.Max(127);
            self.DisplayValue = self.CompAttack;
            self.LEDSlider(false);
            break;
        case "SPEED":
            self.Min(0);
            self.Max(127);
            self.DisplayValue = self.Speed;
            self.LEDSlider(false);
            break;
        case "TIME":
            self.Min(0);
            self.Max((117*128)+127);
            self.DisplayValue = self.DelayTime;
            self.LEDSlider(false);
            break;
        case "FX TYPE":
            self.Min(0);
            self.Max(15);
            self.DisplayValue = self.Value;
            self.LEDSlider(false);
            break;
        default:
            self.Min(0);
            self.Max(127);
            self.DisplayValue = self.Value;
            self.LEDSlider(true);
        }

        self.Style = ko.pureComputed(function() {
            if (!self.LEDSlider()) {
                return "0px 0px";
            }
            let value = self.Value();
            let offset = 0;
            while (value > 0) {
                value -= (offset % 2 === 0) ? 7 : 8; // weird, I know
                offset += 1;
            }
            return "-" + (Math.max(1, offset)*80) + "px 0px";
        }, self);

    }

    return {
        viewModel: Slider,
        template: { require: "text!components/slider/slider.html" }
    };

});
