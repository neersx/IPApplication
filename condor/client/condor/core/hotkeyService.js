angular.module('inprotech.core').factory('hotkeyService', function($transitions, $translate, hotkeys) {
    'use strict';

    var stack = [];
    var hotkeyService = {
        init: function() {
            var oldAdd = hotkeys.add;
            hotkeys.add = function(options) {
                if (options.allowIn == null) {
                    options.allowIn = ['INPUT', 'SELECT', 'TEXTAREA'];
                }

                if (options.persistent == null) {
                    options.persistent = false;
                }

                options.description = $translate.instant(options.description);

                var oldCallback = options.callback;

                // if callback returns true, the event will bubble up otherwise it will stop the default behaviour.
                options.callback = function(event) {
                    if (!oldCallback.apply(null, arguments)) {
                        event.preventDefault();
                    }
                };

                return oldAdd.apply(hotkeys, arguments);
            };

            $transitions.onSuccess({}, hotkeyService.reset);
        },
        reset: function() {
            stack = [];
            hotkeys.purgeHotkeys();
        },
        push: function() {
            stack.push(hotkeyService.clone());
            hotkeys.purgeHotkeys();
        },

        pop: function() {
            hotkeys.purgeHotkeys();
            hotkeyService.add(stack.pop());
        },

        clone: function() {
            var items = _.chain(hotkeys.get() || [])
                .filter(function(a) {
                    return !a.persistent;
                })
                .map(function(a) {
                    return {
                        combo: a.combo[0],
                        description: a.description,
                        allowIn: a.allowIn,
                        callback: a.callback
                    };
                })
                .value();

            return items;
        },

        add: function(items) {
            if (items) {
                items.forEach(function(a) {
                    hotkeys.add(a);
                });
            }
        },

        get: function() {
            return stack;
        }
    };

    return hotkeyService;
});
