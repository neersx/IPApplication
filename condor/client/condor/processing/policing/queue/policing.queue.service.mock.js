angular.module('inprotech.mocks.processing.policing').factory('PolicingQueueServiceMock', function() {
    'use strict';

    var r = {
        get: function() {
            return {
                then: function(cb) {
                    return cb(r.get.returnValue);
                }
            };
        },
        releaseSelected: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        holdSelected: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        deleteSelected: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        releaseAll: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        holdAll: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        deleteAll: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        editNextRunTime: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        getErrors: function() {
            return r.getErrors.returnValue;
        },
        config: function() {
            return {
                permissions: {
                    canAdminister: false,
                    canMaintainWorkflow: false
                }
            };
        },
        getCachedSummary: function() {
            return {
                then: function(cb) {
                    return cb(r.get.returnValue);
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
