angular.module('inprotech.core.extensible.extensions').factory('validatable', function() {
    'use strict';

    return {
        initObject: function(extObj) {
            extObj.$ctx.error = {};
            extObj.hasError = hasError;
            extObj.getError = getError;
            extObj.$subscribe('onRestored', onRestored);
            extObj.$subscribe('onErrorChanged', function(error) {
                var context = extObj.$ctx.parent;
                if (!context) {
                    return;
                }

                if (error) {
                    context.$ctx.errorCount++;
                } else {
                    context.$ctx.errorCount--;
                }
            });
        },

        initContext: function(context) {
            context.$ctx.errorCount = 0;

            context.hasError = function() {
                return context.$ctx.errorCount > 0;
            };

            context.getInvalidItems = function() {
                return context.getItems().filter(function(item) {
                    return item.hasError();
                });
            };
        }
    };

    function hasError(key, val) {
        var self = this;
        if (!angular.isUndefined(val)) {
            var oldErr = self.$ctx.error[key];

            if (val) {
                self.$ctx.error[key] = val;
            } else {
                delete self.$ctx.error[key];
            }

            var newErr = self.$ctx.error[key];

            if (oldErr !== newErr) {
                self.$publish('onErrorChanged', newErr);
            }

            return self;
        }

        if (key) {
            return !!self.$ctx.error[key];
        }

        return Object.keys(self.$ctx.error).length > 0;
    }

    function getError(key) {
        var self = this;
        if (key) {
            return self.$ctx.error[key];
        }
        return null;
    }

    function onRestored() {
        if (!this.hasError()) {
            return;
        }

        this.$ctx.error = {};

        this.$publish('onErrorChanged', false);
    }
});
