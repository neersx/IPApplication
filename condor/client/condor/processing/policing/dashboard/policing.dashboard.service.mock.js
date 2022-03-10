angular.module('inprotech.mocks.processing.policing').factory('policingDashboardServiceMock', function() {
    'use strict';

    var r = {
        permissions: function() {
            return {
                then: function(cb) {
                    return cb(r.permissions.returnValue || {
                        data: {}
                    });
                }
            }
        },
        dashboard: function() {
            return {
                then: function(cb) {
                    return cb(r.dashboard.returnValue || {
                        data: {}
                    });
                }
            }
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
