angular.module('Inprotech.CaseDataComparison')
    .controller('comparisonErrorDetailsController', [
        '$scope', 'item', 'errorView', '$uibModalInstance',

        function($scope, item, errorView, $uibModalInstance) {
            'use strict';

            var init = function() {
                $scope.currentItem = item;
                $scope.errorView = errorView;
            };

            $scope.dismiss = function() {
                $uibModalInstance.close();
            }

            init();
        }
    ]);