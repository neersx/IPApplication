angular.module('inprotech.mocks.configuration.rules.workflows').factory('characteristicsBuilderMock', function() {
    'use strict';

    var r = {
        build: function() {
            return r.build.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
