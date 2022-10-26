/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

define(["knockout", "knockout-mapping", "utils"], function(ko, koMapping, ux) {
    "use strict";

    /**
     * All-purpose sheet handler
     *
     * @param {object}   params           The params object
     * @param {function} params.data      The data item from the parent view
     * @param {function} params.validate  Callback for validation
     */

    function Sheet(params) {

        var self = this;

        /* ----- VIEW MODEL ----- */

        self.originalData = params.data;
        self.validate = params.validate;
        self.onSubmit = params.onSubmit;

        var obj = koMapping.toJSON(self.originalData);
        self.editedData = koMapping.fromJSON(obj);
    }

    Sheet.prototype.submit = function(mustValidate) {
        var self = this;

        if (mustValidate !== false && self.validate && typeof self.validate === "function") {
            if (!self.validate(self.editedData)) {
                return;
            }
        }

        // call onSubmit handler
        if (self.onSubmit && typeof self.onSubmit === "function") {
            self.onSubmit(self.originalData(), self.editedData);
        }

        self.close();
    };

    Sheet.prototype.close = function() {
        var self = this;
        ux.hideSheet(function() {
            self.originalData(null);
        });
    };

    /* ----- CLEAN UP ----- */

    Sheet.prototype.dispose = function() {};

    return Sheet;

});
