angular.module('inprotech.mocks.configuration.general.jurisdictions').factory('JurisdictionsServiceMock', function() {
    'use strict';

    var r = {
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        initialData: function(){
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
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
