angular.module('inprotech.mocks.configuration.general.texttypes').factory('TextTypeServiceMock', function() {
    'use strict';

    var r = {
        searchResults: [],
        savedTextTypeIds: [],
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
                    return cb({
                        id: entityId
                    });
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
                    response.data.result = {
                        result: 'success',
                        updateId: 'A'
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
                        updateId: 'A'
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
        changeTextTypeCode: function() {
            return {
                then: function(cb) {
                    var response = {data: {result: {}}};
                    response.data.result = {
                        result: 'success',
                        updateId: 'B'
                    };
                    return cb(response);
                }
            };
        },
        resetSavedValue: jasmine.createSpy(),
        persistSavedTextTypes: angular.noop,
        markInUseTextTypes: angular.noop
    }

    return r;
});
