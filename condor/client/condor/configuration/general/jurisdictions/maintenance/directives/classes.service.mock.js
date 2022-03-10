angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionClassesServiceMock', function() {
    'use strict';
    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.data.returnValue);
                }
            };
        }
    };

    spyOn(r, 'search').and.callThrough();

    return r;
});
