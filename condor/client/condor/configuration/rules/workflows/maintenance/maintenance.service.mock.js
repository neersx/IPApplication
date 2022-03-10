angular.module('inprotech.mocks.configuration.rules.workflows').factory('workflowsMaintenanceServiceMock', function() {
    'use strict';

    var r = {
        getCharacteristics: function() {
            return {
                then: function(cb) {
                    return cb(r.getCharacteristics.returnValue);
                }
            };
        },
        isCharacteristicField: function() {
            return r.isCharacteristicField.returnValue;
        },
        save: angular.noop,
        picklistEquals: angular.noop,
        createSaveRequestDataForCharacteristics: function() {
            return r.createSaveRequestDataForCharacteristics.returnValue;
        },
        getParent: angular.noop,
        getDescendants: angular.noop,
        resetSuccess: angular.noop
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});