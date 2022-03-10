angular.module('inprotech.mocks').factory('featureDetectionMock', function() {
    'use strict';

    var r = {
        isIe: function() {
            return r.isIe.returnValue;
        },
        hasRelease13: function() {
            return then(r.hasRelease13.returnValue);
        },
        hasRelease16: function () {
            return then(r.hasRelease16.returnValue);
        },
        getAbsoluteUrl: function() {
            return r.getAbsoluteUrl.returnValue;
        }
    };

    var then = function(returnValue) {
        return {
            then: function(cb) {
                return cb({
                    data: returnValue
                });
            }
        };
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});