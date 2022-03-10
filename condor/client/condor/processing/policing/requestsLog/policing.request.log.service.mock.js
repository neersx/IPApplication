angular.module('inprotech.mocks.processing.policing').factory('PolicingRequestLogServiceMock', function() {
    'use strict';

    var r = {
        recent: function() {
            return {
                then: function(cb) {
                    return cb(r.recent.returnValue);
                }
            }
        },
        delete: function() {
            return {
                then: function(cb) {
                    return cb(r.delete.returnValue);
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
