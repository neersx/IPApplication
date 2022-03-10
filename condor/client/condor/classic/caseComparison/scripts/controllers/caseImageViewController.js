angular.module('Inprotech.CaseDataComparison')
    .controller('caseImageViewController', [
        '$scope', 'imageItem', '$uibModalInstance',

        function($scope, imageItem, $uibModalInstance) {
            'use strict';

            var init = function() {
                $scope.caseImage = imageItem;
            };

            $scope.dismiss = function() {
                $uibModalInstance.close();
            }

            init();
        }
    ]);