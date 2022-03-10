angular.module('inprotech.mocks')
    .service('stateContextMock', function() {
        'use strict';

        var r = {
            getCurrentStateUrl: function() {
                return r.getCurrentStateUrl.returnValue;
            },
            getCurrentStateInfo: function() {
                return r.getCurrentStateUrl.returnValue;
            }
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });

        return r;
    });