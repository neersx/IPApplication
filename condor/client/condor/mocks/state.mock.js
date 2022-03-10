angular.module('inprotech.mocks').factory('stateMock', function() {
    'use strict';

    var r = {
        go: _.noop,
        current: {
            name: 'name',
            from: {
                name: 'fromName'
            },
            data: {
                pageTitle: 'view'
            }
        },
        reload: _.noop,
        get: _.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
