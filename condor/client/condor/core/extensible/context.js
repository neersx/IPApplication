angular.module('inprotech.core.extensible').factory('ExtObjContext', function(ExtObject, pubsub) {
    'use strict';

    function ExtObjContext(extensions) {
        if (!Array.isArray(extensions)) {
            throw new Error('extensions must be an array.');
        }

        var self = this;

        self.$ctx = {
            listeners: {},
            extensions: extensions,
            items: [],
            map: {}
        };

        extensions.forEach(function(a) {
            if (a.initContext) {
                a.initContext(self);
            }
        });
    }

    angular.extend(ExtObjContext.prototype, pubsub, {
        find: function(key) {
            return this.$ctx.map[key];
        },

        getItems: function() {
            return this.$ctx.items;
        },

        attach: function(obj, keyName) {
            var self = this;
            var key = obj[keyName || 'id'];

            var extObj = new ExtObject(obj, self.$ctx.extensions);
            extObj.$ctx.parent = self;

            if (key !== null) {
                self.$ctx.map[key] = extObj;
            }

            self.$ctx.items.push(extObj);

            return extObj;
        },

        $broadcast: function(methodName) {
            var args = Array.prototype.slice.call(arguments).slice(1);

            this.$ctx.items.forEach(function(item) {
                if (angular.isFunction(item[methodName])) {
                    item[methodName].apply(item, args);
                }
            });
        }
    });

    return ExtObjContext;
});
