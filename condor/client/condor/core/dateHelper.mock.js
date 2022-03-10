angular.module('inprotech.mocks.core').factory('dateHelperMock', function() {
    'use strict';

    var r = {
        convertForDatePicker: function(theDate) {
            if (theDate) {
                return theDate;
            }
            return r.convertForDatePicker.returnValue;
        },
        toLocal: function(input) {
            return input.toISOString().split('T')[0];
        }
    };

    return r;
});