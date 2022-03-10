angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionValidCombinationsServiceMock', function() {
    'use strict';

    var r = {
        hasCombinations: function() {
            return {
                then: function(cb) {
                    return cb(r.hasCombinations.returnValue);
                }
            };
        }
    };

    spyOn(r, 'hasCombinations').and.callThrough();

    return r;
});
