angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsCharacteristicsServiceMock', function() {
    'use strict';

    var r = {
        validate: angular.noop,
        setValidation: angular.noop,
        hasErrors: function() {
            return r.hasErrors.returnValue;
        },
        resetErrors: function() {
            return r.resetErrors.returnValue;
        },
        validCombinationMap: function() {
            return r.validCombinationMap.returnValue;
        },
        initController: function() {
            return r.initController.returnValue;
        },
        showExaminationType: angular.noop,
        showRenewalType: angular.noop,
        isCharacteristicField: function() {
            return r.isCharacteristicField.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
