angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsDueDateCalcServiceMock', function() {
    'use strict';

    var r = {
        updateSaveDueDate: angular.noop,
        initSettingsViewModel: angular.noop,
        getSettingsForSave: angular.noop,
        getDueDateCalcs: function() {
            return {
                then: jasmine.createSpy('getDueDateCalcsThen', function(callback) {
                    return callback(r.getDueDateCalcs.returnValue);
                }).and.callThrough()
            };
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
