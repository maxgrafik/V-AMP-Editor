/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

require.config({
    baseUrl: "js/vendor",
    paths: {
        knockout:   "knockout-3.5.1",
        app:        "../app/",
        components: "../app/components",
        dialog    : "../app/dialogs"
    }
});

require(["domReady!", "knockout"], function(doc, ko) {
    "use strict";

    // ko.options.deferUpdates = true;
    ko.components.register("App", { require: "app/app" });
    ko.applyBindings();

});
