angular.module('inprotech.mocks').factory('ApiResolverServiceMock', function() {
    'use strict';

    var service = {
        resolve: function() {}
    };

    test.spyOnAll(service);

    return service;
});
