angular.module('inprotech.mocks.configuration.general.standinginstructions').factory('StandingInstructionsServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        saveChanges: function() {
            return {
                then: function(cb) {
                    return cb(r.saveChanges.returnValue);
                }
            };
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return function() {
        return r;
    };
});
