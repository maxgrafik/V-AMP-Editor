/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

define(["knockout", "utils"], function(ko, ux) {
    "use strict";

    ko.dirtyFlag = function(data) {
        let hash = ko.observable(ko.toJSON(data));
        let fn = function() {};
        fn.isDirty = ko.computed(function() {
            return (hash() !== ko.toJSON(data));
        }).extend({ notify: "always" });
        fn.setClean = function() {
            hash(ko.toJSON(data));
        };
        fn.getDirty = function() {
            const a = JSON.parse(hash());
            const b = JSON.parse(ko.toJSON(data));
            const c = [];
            for (let i = 0; i < a.length; i++) {
                if (ko.toJSON(a[i]) !== ko.toJSON(b[i])) {
                    c.push(b[i]);
                }
            }
            for (let j = a.length; j < b.length; j++) {
                c.push(b[j]);
            }
            return c;
        };
        fn.dispose = function() {
            fn.isDirty.dispose();
            hash = null;
        };
        return fn;
    };

    ko.bindingHandlers.sheet = {
        init: function(element, valueAccessor, allBindings, viewModel, bindingContext) {
            const showSheet = ko.pureComputed(function() {
                const observable = valueAccessor();
                return ko.unwrap(observable) !== null;
            });
            ko.applyBindingsToNode(element, {
                if: showSheet
            }, bindingContext);
        },
        update: function(element, valueAccessor) {
            const observable = valueAccessor();
            const value = ko.unwrap(observable);
            if (value !== null) {
                ux.showSheet(element, true);
            }
        }
    };

});
