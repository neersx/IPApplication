angular.module('inprotech.mocks').factory('hotkeyServiceMock', function() {
    'use strict';
    
    var r = {
        init: angular.noop,
        reset: angular.noop,
        push: angular.noop,
        pop: angular.noop,
        clone: angular.noop,
        add: angular.noop,
        get: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
