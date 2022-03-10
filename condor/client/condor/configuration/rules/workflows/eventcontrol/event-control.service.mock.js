angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsEventControlServiceMock', function() {
    'use strict';

    var r = {
        getMatchingNameTypes: function() {
            return {
                then: jasmine.createSpy('getMatchingNameTypesThen', function(callback) {
                    return callback(r.getMatchingNameTypes.returnValue);
                }).and.callThrough()
            };
        },
        getDateComparisons: function() {
            return {
                then: jasmine.createSpy('getDateComparisonsThen', function(callback) {
                    return callback(r.getDateComparisons.returnValue);
                }).and.callThrough()
            };
        },
        getSatisfyingEvents: function() {
            return {
                then: jasmine.createSpy('getSatisfyingEventsThen', function(callback) {
                    return callback(r.getSatisfyingEvents.returnValue);
                }).and.callThrough()
            };
        },
        getDesignatedJurisdictions: function() {
            return {
                then: jasmine.createSpy('getDesignatedJurisdictionsThen', function(callback) {
                    return callback(r.getDesignatedJurisdictions.returnValue);
                }).and.callThrough()
            };
        },
        getDateLogicRules: angular.noop,
        getEventsToUpdate: angular.noop,
        getReminders: function() {
            return {
                then: jasmine.createSpy('getRemindersThen', function(callback) {
                    return callback(r.getReminders.returnValue);
                }).and.callThrough()
            };
        },
        getDocuments: function() {
            return {
                then: jasmine.createSpy('getDocumentsThen', function(callback) {
                    return callback(r.getDocuments.returnValue);
                }).and.callThrough()
            };
        },
        translatePeriodType: function() {
            return r.translatePeriodType.returnValue;
        },
        updateEventControl: function() {
            return {
                then: jasmine.createSpy('updateEventControlThen', function(callback) {
                    if (r.updateEventControl.returnValue) {
                        return callback(r.updateEventControl.returnValue);
                    }
                    return callback({
                        data: {
                            status: 'success'
                        }
                    });

                }).and.callThrough()
            };
        },
        isDuplicated: _.constant(false),
        isApplyEnabled: angular.noop,
        mapGridDelta: function() {
            return r.mapGridDelta.returnValue;
        },
        initEventPicklistScope: function(extendScope) {
            return extendScope;
        },
        formatPicklistColumn: angular.noop,
        relativeCycles: {},
        translateRelativeCycle: angular.noop,
        getDefaultRelativeCycle: angular.noop,
        setEditedAddedFlags: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
