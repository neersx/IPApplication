angular.module('inprotech.mocks.processing.policing').factory('PolicingQueueFilterServiceMock', function() {
    'use strict';

    var r = {
        getFilters: function() {
            return r.getFilters.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
