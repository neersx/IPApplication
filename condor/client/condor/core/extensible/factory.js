angular.module('inprotech.core.extensible').factory('ExtObjFactory', function(ExtObjContext, ExtObject) {
    'use strict';

    function ExtObjFactory() {
        this.$extensions = [];
    }

    var $injector = angular.injector(['inprotech.core.extensible.extensions']);
    var defaultExtensions = ['restorable', 'dirtyCheck', 'savable', 'validatable'];

    ExtObjFactory.prototype = {
        useDefaults: function() {
            this.use.call(this, defaultExtensions);
            return this;
        },

        use: function(ext) {
            useCore(this, ext);

            validateExtension(this.$extensions);

            return this;
        },

        createObj: function(rawObj) {
            return new ExtObject(rawObj, this.$extensions);
        },

        createContext: function() {
            return new ExtObjContext(this.$extensions);
        }
    };

    return ExtObjFactory;

    function validateExtension(extensions) {
        extensions.forEach(function(ext) {
            if (!ext.dependsOn) {
                return null;
            }

            ext.dependsOn.forEach(function(dep) {
                var found = extensions.some(function(e) {
                    return e.name === dep;
                });

                if (!found) {
                    throw new Error('dependency not found: ' + dep);
                }
            });
        });
    }

    function useCore(factory, ext) {
        if (angular.isString(ext)) {
            var item = $injector.get(ext);
            item.name = item.name || ext;
            factory.$extensions.push(item);
        } else if (Array.isArray(ext)) {
            ext.forEach(function(a) {
                useCore(factory, a);
            });
        } else {
            factory.$extensions.push(ext);
        }
    }
});
