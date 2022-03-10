angular.module('inprotech.mocks.processing.policing').factory('policingServerServiceMock', function() {
    'use strict';

    var r = {
        canAdminister: function() {
            return {
                then: function() {
                    return r.canAdminister.returnValue;
                }
            };
        },
        turnOff: function() {
            return {
                then: function() {
                    return {
                        then: function() {
                            return r.turnOff.returnValue;
                        }
                    };
                }
            };
        },
        turnOn: function() {
            return {
                then: function() {
                    return r.turnOn.returnValue;
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
