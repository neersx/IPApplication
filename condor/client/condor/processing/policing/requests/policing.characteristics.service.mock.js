angular.module('inprotech.mocks.processing.policing')
.factory('policingCharacteristicsServiceMock', function() {
    'use strict';

    var r = {
        validate: angular.noop,
        setValidation: angular.noop,
        extendPicklistQuery: function() {
            return r.extendPicklistQuery.returnValue;
        },
        isDateOfLawDisabled: function() {
            return r.isDateOfLawDisabled.returnValue;
        },
        isCaseCategoryDisabled: function() {
            return r.isCaseCategoryDisabled.returnValue;
        },
        validCombinationMap: function() {
            return r.validCombinationMap.returnValue;
        },
        isCaseReferenceSelected: function() {
            return r.isCaseReferenceSelected.returnValue;
        },
        initController: function() {
            return r.initController.returnValue;
        }
    };

    Object.keys(r).forEach(function(key) {
        if (angular.isFunction(r[key])) {
            spyOn(r, key).and.callThrough();
        }
    });

    return r;
});
