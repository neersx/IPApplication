angular.module('inprotech.mocks').factory('dateServiceMock', function() {
    'use strict';

    var service = {
        format: function() {}
    };

    test.spyOnAll(service);

    return service;
});
