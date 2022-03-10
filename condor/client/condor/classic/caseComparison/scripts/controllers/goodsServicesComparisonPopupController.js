angular.module('Inprotech.CaseDataComparison')
    .controller('goodsServicesComparisonPopupController', [
        '$scope', 'item', '$uibModalInstance',

        function($scope, item, $uibModalInstance) {
            'use strict';

            var init = function() {
                $scope.currentItem = item;
            };

            $scope.dismiss = function() {
                $uibModalInstance.close();
            }

            init();
        }
    ]);