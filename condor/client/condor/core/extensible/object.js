angular.module('inprotech.core.extensible').factory('ExtObject', function(pubsub) {
    'use strict';

    function ExtObject(obj, extensions) {
        if (!angular.isObject(obj)) {
            throw new Error('obj must be an object.');
        }

        if (!Array.isArray(extensions)) {
            throw new Error('extensions must be an array.');
        }

        var self = this;
        self.$ctx = {
            obj: obj,
            listeners: {}
        };

        extensions.forEach(function(a) {
            if (a.initObject) {
                a.initObject(self);
            }
        });

        Object.keys(obj).filter(function(key) {
            return /^[$_]/.test(key) === false;
        }).forEach(function(key) {
            Object.defineProperty(self, key, {
                get: function() {
                    return self.$ctx.obj[key];
                },

                set: function(val) {
                    var oldVal = self.$ctx.obj[key];
                    self.$ctx.obj[key] = val;

                    self.$publish('onValueChanged', key, val, oldVal);
                }
            });
        });
    }

    angular.extend(ExtObject.prototype, pubsub, {
        getRaw: function() {
            return this.$ctx.obj;
        }
    });

    return ExtObject;
});
