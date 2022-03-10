angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsMaintenanceEntriesServiceMock', function() {
    'use strict';

    var mock = {
        getCharacteristics: function() {
            return {
                then: function(cb) {
                    return cb(mock.getCharacteristics.returnValue);
                }
            };
        },
        getEntries: function() {
            return {
                then: function(cb) {
                    return cb(mock.getEntries.returnValue);
                }
            };
        },
        searchEntryEvents: function() {
            return {
                then: function(cb) {
                    return cb(mock.searchEntryEvents.returnValue);
                }
            };
        },
        entryIds: function() {
            return mock.entryIds.returnValue;
        },
        reorderEntry: angular.noop,
        reorderDescendantsEntry: angular.noop,
        getDescendantsWithInheritedEntry: angular.noop,
        confirmDeleteWorkflow: angular.noop,
        deleteEntries: angular.noop
    };

    Object.keys(mock).forEach(function(key) {
        if (angular.isFunction(mock[key])) {
            spyOn(mock, key).and.callThrough();
        }
    });

    return mock;
});
