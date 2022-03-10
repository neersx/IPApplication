angular.module('inprotech.mocks.core').factory('messageBrokerMock', function() {
    'use strict';

    var r = {
        subscribe: function(binding, callback) {
            callback(binding);
        },
        connect: angular.noop,
        disconnect: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
