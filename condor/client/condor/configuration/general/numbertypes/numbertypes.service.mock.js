angular.module('inprotech.mocks.configuration.general.numbertypes').factory('NumberTypeServiceMock', function() {
    'use strict';

    var r = {
        savedNumberTypeIds: [],
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
                    return cb({id: entityId});
                }
            };
        },
        add: function() {
            return {
                then: function(cb) {
                    var response = {data: {result: {}}};
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
                    var response = {data: {result: {}}};
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
        updateNumberTypesSequence: function() {
            return {
                then: function(cb) {
                     var response = {data: {result: {}}};
                    response.data.result = {
                        result: 'success'
                    };
                    return cb(response);
                }
            };
        },
        changeNumberTypeCode: function() {
            return {
                then: function(cb) {
                    var response = {data: {result: {}}};
                    response.data.result = {
                        result: 'success',
                        updateId: 3
                    };
                    return cb(response);
                }
            };
        },
        resetSavedValue: jasmine.createSpy(),
        persistSavedNumberTypes: angular.noop,
        markInUseNumberTypes: angular.noop
    };
    return r;
});
