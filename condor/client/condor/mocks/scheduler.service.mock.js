angular.module('inprotech.mocks').factory('schedulerMock', function () {
    'use strict';

    var scheduler = {
        runOutsideZone: angular.noop
    };


    return scheduler;
});
