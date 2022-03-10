angular.module('inprotech.configuration.rules.workflows').factory('sharedService', function() {
    'use strict';

    var defaults = {
        search: angular.noop,
        isSearchDisabled: angular.noop,
        hasOffices: false,
        lastSearch: null,
        characteristics: null,
        criteria: null,
        case: null,
        event: null,
        selectedEventInDetail: null,
        includeProtectedCriteria: false
    };

    return angular.extend({}, defaults, {
        reset: function() {
            angular.extend(this, defaults);
        }
    });
});
