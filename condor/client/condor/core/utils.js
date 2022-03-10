angular.module('inprotech.core').factory('utils', function($q, $log) {
    'use strict';

    function Cancellable() {
        this.reset();
    }

    Cancellable.prototype = {
        cancel: function() {
            if (this.deferred) {
                this.deferred.resolve();
            }

            this.reset();
        },

        reset: function() {
            this.deferred = $q.defer();
            this.promise = this.deferred.promise;
        }
    };

    return {
        extendWithDefaults: function(source, defaults) {
            _.each(defaults, function(value, key) {
                if (typeof source[key] === 'undefined') {
                    source[key] = value;
                }
            });
        },

        cancellable: function() {
            return new Cancellable();
        },

        debug: function() {
            if (!window.INPRO_DEBUG) {
                return;
            }

            var args = _.toArray(arguments);

            $log.debug.apply($log, args);
        },
        safeApply: function(scope, fn) {
            var phase = scope.$root.$$phase;
            if (phase === '$apply' || phase === '$digest') {
                if (fn) {
                    scope.$eval(fn);
                }
            } else {
                if (fn) {
                    scope.$apply(fn);
                } else {
                    scope.$apply();
                }
            }
        },
        steps: function() {
            var steps = _.toArray(arguments);
            var next = function(index) {
                return function() {
                    if (index < steps.length) {
                        steps[index + 1](next(index + 1));
                    }
                }
            };

            steps[0](next(0));
        }
    };
});
