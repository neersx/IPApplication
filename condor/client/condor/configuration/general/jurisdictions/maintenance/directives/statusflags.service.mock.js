angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionStatusFlagsServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        copyProfiles: function() {
            return {
                then: function(cb) {
                    return cb({ data: {} });
                }
            };
        },
        registrationStatus: []
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});