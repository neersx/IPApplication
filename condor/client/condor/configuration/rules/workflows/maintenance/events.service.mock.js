angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsMaintenanceEventsServiceMock', function() {
    'use strict';

    var r = {
        addEventWorkflow: angular.noop,
        addEvent: angular.noop,
        addEventId: angular.noop,
        removeEventIds: angular.noop,
        getEvents: function() {
            return {
                then: jasmine.createSpy('getEventsThen', function(callback) {
                    return callback(r.getEvents.returnValue);
                }).and.callThrough()
            };
        },
        getEventFilterMetadata: angular.noop,
        searchEvents: function() {
            return {
                then: jasmine.createSpy('searchEventsThen', function(callback) {
                    return callback(r.searchEvents.returnValue);
                }).and.callThrough()
            };
        },
        eventIds: function() {
            return r.eventIds.returnValue || [];
        },
        confirmDeleteWorkflow:angular.noop,
        deleteEvents: angular.noop,
        refreshEventIds: angular.noop,
        isEventNewlyAdded: angular.noop,
        resetNewlyAddedEventIds: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key]) && !r[key].and) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
