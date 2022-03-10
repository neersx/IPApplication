angular.module('Inprotech.CaseDataComparison')
    .controller('errorViewController', [
        '$scope', 'modalService',

        function($scope, modalService) {
            'use strict';
            $scope.errorView = 'errorView';
            $scope.details = [];

            $scope.$on('error', function(evt, notification) {
                $scope.details = notification ? notification.body : null;
            });

            $scope.showStackTrace = function(item) {
                $scope.currentItem = item;
                openErrorDetailsDialog(item);
            };

            var openErrorDetailsDialog = function(errors) {
                modalService.open('ComparisonErrorDetails', $scope, {
                    item: errors,
                    errorView: function() { return 'errorView'; }
                });
            };
        }
    ]);