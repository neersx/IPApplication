angular.module('inprotech.mocks.configuration.general.dataitem').factory('DataItemServiceMock', function() {
    'use strict';

    var r = {
        savedDataItemIds: [],
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
        add: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data = {
                        result: 'success',
                        updatedId: 1
                    };
                    return cb(response);
                }
            };
        },
        get: function(entityId) {
            return {
                then: function(cb) {
                    return cb({
                        id: entityId
                    });
                }
            };
        },
        update: function() {
            return {
                then: function(cb) {
                    var response = {
                        data: {
                            result: {}
                        }
                    };
                    response.data = {
                        result: 'success',
                        updatedId: 1
                    };
                    return cb(response);
                }
            };
        },
        validate: function() {
            return {
                then: function(cb) {
                    var response = { data: null };
                    return cb(response);
                }
            };
        },
        validatePicklistSql: function() {
            return {
                then: function(cb) {
                    var response = { data: null };
                    return cb(response);
                }
            };
        }
    };
    return r;
});