angular.module('inprotech.mocks.processing.policing')
.factory('policingCharacteristicsBuilderMock', function() {
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
