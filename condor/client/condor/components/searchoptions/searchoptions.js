angular.module('inprotech.components.searchOptions').directive('ipSearchOptions', function(focusService) {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: {
            onSearch: '&',
            onClear: '&',
            onValidate: '&',
            isSearchDisabled: '&',
            isResetDisabled: '&'
        },
        templateUrl: 'condor/components/searchoptions/searchoptions.html',
        link: function(scope, element) {
            scope.setFocus = function() {
                focusService.autofocus(element);
            };

            scope.doSearch = _.debounce(function() {
                if (!scope.isSearchDisabled()) {
                    scope.onSearch();
                }
            }, 100, true);
        }
    };
});
