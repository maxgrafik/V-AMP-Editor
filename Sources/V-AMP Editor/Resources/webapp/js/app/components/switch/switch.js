/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

define(["knockout"], function(ko) {
    "use strict";

    function Switch(params) {

        const self = this;

        self.Value = ko.pureComputed({
            read: function () {
                return params.value() !== 0;
            },
            write: function(value) {
                params.value(value ? 127 : 0);
            },
            owner: this
        });
        self.Label = ko.observable(params.label);

    }

    return {
        viewModel: Switch,
        template: { require: "text!components/switch/switch.html" }
    };

});
