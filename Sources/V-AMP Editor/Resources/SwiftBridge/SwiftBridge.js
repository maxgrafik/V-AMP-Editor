/**
 * Swift Bridge
 * @copyright 2022 Hendrik Meinl
 */

(function (root, factory) {
    root.SwiftBridge = factory();
}(this, function () {

    const eventListeners = {};

    /**
     * Initialize SwiftBridge
     * Add a single event listener for SwiftBridge events to window
     */
    function init() {

        window.addEventListener("SwiftBridgeEvent", (customEvent) => {

            // get event type from CustomEvent
            const event = customEvent.detail && customEvent.detail.event || null;

            // check if any eventListeners are registered for this type
            if (event && Object.prototype.hasOwnProperty.call(eventListeners, event)) {

                // get event payload (if any)
                const data = customEvent.detail.data || null;

                // call each listener
                const listeners = eventListeners[event];
                listeners && listeners.forEach(callback => {
                    if (callback && typeof callback === "function") {
                        callback(data);
                    }
                });
            }
        });

        console.log("SwiftBridge ready");
    }

    /**
     * Register an event listener
     * @param {string}   event    - The event we're interested in (e.g. "didSelectMenuItem")
     * @param {function} callback - The callback function taking 1 parameter (data)
     */
    function on(event, callback) {
        if (typeof event !== "string") {
            console.error("Parameter event is not a string");
            return;
        }
        if (!Object.prototype.hasOwnProperty.call(eventListeners, event)) {
            eventListeners[event] = [];
        }
        eventListeners[event].push(callback);
    }

    /**
     * Post message
     * @param {string} event - The event to send
     * @param {any}    data  - The data to send with the event (or null)
     */
    function post(event, data) {
        if (typeof event !== "string") {
            console.error("Parameter event is not a string");
            return;
        }
        window.webkit.messageHandlers.SwiftBridge.postMessage({
            event: event,
            data: data
        });
    }

    /**
     * Shows a native NSAlert
     * @param {object}   alertConfig - An object describing the alert properties
     *
     * @example
     * alertConfig = {
     *     msgID: {string},
     *     title: {string},
     *     text:  {string},
     *     style: {string}, - only "warning" is currently interpreted
     *     buttons: [
     *         {
     *           title: {string},
     *           destructive: {boolean} - see NSButton for meaning
     *         }
     *     ]
     * }
     */
    function alert(alertConfig) {
        window.webkit.messageHandlers.SwiftBridge.postMessage({
            event: "Alert",
            data: alertConfig
        });
    }

    init();

    return {
        on        : on,
        post      : post,
        alert     : alert
    };

}));
