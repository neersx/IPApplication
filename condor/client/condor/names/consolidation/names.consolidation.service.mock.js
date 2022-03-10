angular.module('inprotech.mocks').service('NamesConsolidationServiceMock', function() {
    'use strict';
   
    var r = {
        consolidate: function() {
            return {
                then: function(cb) {
                    return cb(r.consolidate.returnValue);
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