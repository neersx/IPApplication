angular.module('inprotech.mocks.configuration.general.namerestrictions').factory('NameRestrictionsServiceMock', function() {
    'use strict';

    var r = {
        savedNameRestrictionIds: [],
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
                    return cb({ id: entityId, description: 'entity description' });
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
        resetSavedValue: jasmine.createSpy(),
        persistSavedNameRestrictions: angular.noop,
        markInUseNameRestrictions: angular.noop
    };
    return r;
});