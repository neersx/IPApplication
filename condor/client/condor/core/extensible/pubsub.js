angular.module('inprotech.core.extensible').factory('pubsub', function() {
    'use strict';

    return {
        $subscribe: function(evt, listener) {
            if (!angular.isString(evt)) {
                throw new Error('event must be a string.');
            }

            if (!angular.isFunction(listener)) {
                throw new Error('listener must be a function');
            }

            var self = this;
            var listeners = self.$ctx.listeners[evt];

            if (!listeners) {
                listeners = self.$ctx.listeners[evt] = [];
            }

            listeners.push(listener);
        },

        $publish: function(evt) {
            var self = this;
            var listeners = self.$ctx.listeners[evt];
            if (!listeners) {
                return;
            }

            var args = Array.prototype.slice.call(arguments);
            args.shift();

            listeners.forEach(function(a) {
                a.apply(self, args);
            });
        }
    };
});
