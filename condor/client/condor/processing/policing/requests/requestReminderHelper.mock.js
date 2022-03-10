angular.module('inprotech.mocks.processing.policing')
    .factory('requestReminderHelperMock', function() {
        var r = {
            init: angular.noop,
            setForDays:  angular.noop,
            positiveOrEmptyDays:  angular.noop,
            setDatesValidityByDays:  angular.noop,
            addDays:  angular.noop,
            convertForDatePicker:  angular.noop,
            areDatesEqual:  angular.noop
        };

        Object.keys(r).forEach(function(key) {
            if (angular.isFunction(r[key])) {
                spyOn(r, key).and.callThrough();
            }
        });
        return r;
    });
