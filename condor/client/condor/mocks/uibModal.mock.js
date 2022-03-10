angular.module('inprotech.mocks').factory('uibModalMock', function() {
    'use strict';

    var service = {
        open: function() {}
    };

    test.spyOnAll(service);
    
    return service;
});
