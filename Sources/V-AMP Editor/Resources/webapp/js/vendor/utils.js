/**!
 * V-AMP Editor
 *
 * @copyright 2022 Hendrik Meinl | maxgrafik.de
 */

define(function() {
    "use strict";

    /* --- animation event --- */

    /* eslint-disable-next-line no-extra-boolean-cast */
    var animationEvent = (!!window.WebKitAnimationEvent) ? "webkitAnimationEnd" : "animationend";


    /* --- element manipulation --- */

    function make(tagName, attrs) {
        var el = document.createElement(tagName);
        for (var prop in attrs) {
            el.setAttribute(prop, attrs[prop]);
        }
        return el;
    }


    /* --- css class handling --- */

    function hasClass(el, className) {
        return el.classList ? el.classList.contains(className) : new RegExp("\\b"+ className+"\\b").test(el.className);
    }

    function addClass(el, className, callback) {
        if (el.classList) {
            el.classList.add(className);
        } else if (!hasClass(el, className)) {
            el.className += " " + className;
        }
        if (callback && typeof callback === "function") {
            el.addEventListener(animationEvent, function listener() {
                el.removeEventListener(animationEvent, listener);
                callback.call(this);
            });
        }
    }

    function removeClass(el, className, callback) {
        if (el.classList) {
            el.classList.remove(className);
        } else {
            el.className = el.className.replace(new RegExp("\\b"+ className+"\\b", "g"), "");
        }
        if (callback && typeof callback === "function") {
            el.addEventListener(animationEvent, function listener() {
                el.removeEventListener(animationEvent, listener);
                callback.call(this);
            });
        }
    }


    /* --- sheets & modals --- */

    function showSheet(target) {
        var el = (typeof target === "string") ? document.getElementById(target) : target;
        if (el) {
            var parent = el.parentElement;
            var backdrop = make("div", { class: "sheet-backdrop" });

            parent.insertBefore(backdrop, el);
            addClass(backdrop, "sheetBackdropIn", function() {
                removeClass(backdrop, "sheetBackdropIn");
            });

            addClass(el, "sheetIn", function() {
                removeClass(el, "sheetIn");
            });
            el.removeAttribute("hidden");
        }
    }

    function hideSheet(callback) {
        var dlg = document.querySelector("dialog.sheet:not([hidden])");
        if (dlg) {
            var backdrop = document.getElementsByClassName("sheet-backdrop");
            if (backdrop.length > 0) {
                addClass(backdrop[0], "sheetBackdropOut", function() {
                    removeClass(backdrop[0], "sheetBackdropOut");
                    backdrop[0].parentElement.removeChild(backdrop[0]);
                });
            }

            addClass(dlg, "sheetOut", function() {
                this.setAttribute("hidden", "");
                removeClass(this, "sheetOut");
                if (callback && typeof callback === "function") {
                    callback();
                }
            });
        }
    }


    return {
        showSheet         : showSheet,
        hideSheet         : hideSheet
    };

});
