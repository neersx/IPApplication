angular.module('Inprotech.CaseDataComparison')
    .controller('officialNumbersComparisonController', [
        '$scope',
        function($scope) {
            'use strict';

            $scope.toggleNumberSelection = function(item) {
                if (!item.id && !item.number.updated) {
                    item.eventDate.updated = false;
                }
            };

            $scope.toggleDateSelection = function(item) {
                if (!item.id && !item.number.updated) {
                    item.number.updated = true;
                }
            };
        }
    ]);
