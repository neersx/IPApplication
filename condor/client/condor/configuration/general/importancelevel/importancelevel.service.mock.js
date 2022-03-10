angular.module('inprotech.mocks.configuration.general.importancelevel').factory('ImportanceLevelServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        }
    };
    return r;
});