angular.module('inprotech.mocks.configuration.general.nametypes').factory('NameTypeServiceMock', function() {
    'use strict';

    var r = {
        savedNameTypeIds: [],
        searchResults: [],
        search: function() {
            return {
                then: function(cb) {
                    return cb(r.search.returnValue);
                }
            };
        },
        get: function(entityId) {
            return {
                then: function(cb) {
                    return cb({ id: entityId });
                }
            };
        },
        add: function() {
            return {
                then: function(cb) {
                    var response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success',
                        updateId: 1
                    };
                    return cb(response);
                }
            };
        },
        update: function() {
            return {
                then: function(cb) {
                    var response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success',
                        updateId: 1
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
        updateNameTypesSequence: function() {
            return {
                then: function(cb) {
                    var response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success'
                    };
                    return cb(response);
                }
            };
        },
        resetSavedValue: jasmine.createSpy(),
        persistSavedNameTypes: angular.noop,
        markInUseNameTypes: angular.noop
    };
    return r;
});