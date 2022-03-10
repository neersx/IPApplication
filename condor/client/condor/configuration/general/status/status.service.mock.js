angular.module('inprotech.mocks.configuration.general.status').factory('StatusServiceMock', function() {
    'use strict';

    var r = {
        savedStatusIds: [],
        search: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {}
                    };
                    return cb(response);
                }
            };
        },
        get: function(entityId) {
            return {
                then: function(cb) {
                    return cb({
                        id: entityId,
                        name: 'entity description'
                    });
                }
            };
        },
        add: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: 'success',
                            updateId: 1
                        }
                    };
                    return cb(response);
                }
            };
        },
        update: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: 'success',
                            updateId: 1
                        }
                    };
                    return cb(response);
                }
            };
        },
        delete: function() {
            return {
                then: function(cb) {
                    return cb();
                }
            };
        },
        persistSavedStatuses: angular.noop,
        markInUseStatuses: angular.noop
    };
    return r;
});
