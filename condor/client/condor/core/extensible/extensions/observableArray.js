/* This is a simple implementation of observable array.
   It only monitors collection changes when invoking methods like push, splice etc.
   Notice replacing items in array will not raise any events.
*/
angular.module('inprotech.core.extensible.extensions').factory('observableArray', function() {
    'use strict';

    var arrayMethods = ['push', 'pop', 'shift', 'unshift', 'splice'];

    return {
        dependsOn: ['dirtyCheck'],
        initObject: function(extObj) {
            initialise(extObj);
            extObj.$subscribe('onRestored', function() {
                initialise(extObj);
            });
        }
    };

    function initialise(extObj) {
        Object.keys(extObj.$ctx.obj).forEach(function(key) {
            var prop = extObj.$ctx.obj[key];
            if (Array.isArray(prop)) {
                observe(prop, function() {
                    extObj.$publish('onValueChanged', key, extObj.$ctx.obj[key]);
                });
            }
        });
    }

    function observe(array, onCollectionChanged) {
        arrayMethods.forEach(function(method) {
            array[method] = function() {
                Array.prototype[method].apply(array, arguments);
                if (onCollectionChanged) {
                    onCollectionChanged();
                }
            };
        });
    }
});
