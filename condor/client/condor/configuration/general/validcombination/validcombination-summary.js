angular.module('inprotech.configuration.general.validcombination').directive('iptValidCombinationSummary', function () {
    'use strict';

    return {
        restrict: 'E',
        transclude: true,
        scope: {
            addValidCombination: '&',
            searchType: '@'
        },
        templateUrl: 'condor/configuration/general/validcombination/validcombination-summary.html'
    };
});
