angular.module('inprotech.mocks').factory('pagerHelperServiceMock', function() {
    'use strict';
    var r = {
        getPageForId: function() {
            return r.getPageForId.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});