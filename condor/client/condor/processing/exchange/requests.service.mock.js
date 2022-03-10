angular.module('inprotech.mocks.processing.exchange').factory('ExchangeQueueServiceMock', function() {
    'use strict';

    var r = {
        get: function() {
            return {
                then: function(cb) {
                    return cb(r.get.returnValue);
                }
            };
        },
        reset: function() {
            return {
                then: function(cb) {
                    cb(r.reset.returnValue);
                    return this;
                }
            };
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
