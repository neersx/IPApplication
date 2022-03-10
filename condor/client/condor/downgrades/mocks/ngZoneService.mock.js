angular.module('inprotech.mocks.downgrades').factory('ngZoneServiceMock', function() {
    'use strict';
    
    var r = {
        runOutsideAngular: function(fn) {
            fn();
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});


