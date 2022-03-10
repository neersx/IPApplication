angular.module('inprotech.mocks').factory('PersistablesMock', function() {
    'use strict';

    var service = {
        prepare: function(entity, action, selectedItem) {
            return {
                state: null,
                template: null,
                entry: {$then: function(callback){callback(selectedItem)}},
                api: null
            };
        }
    };

    test.spyOnAll(service);

    return service;
});
