angular.module('Inprotech.CaseDataComparison')
    .directive('detailView', ['url', function(url) {
        'use strict';

        return {
            restrict: 'E',
            replace: false,
            transclude: false,
            scope: {
                notification: '=',
                scrollTo: '=?',
                canUpdateCase: '=',
                hideDuplicateWarning: '=',
                onNavigateToDuplicateView: '&'
            },
            templateUrl: url.of('caseComparison/detail-view.html'),
            controller: ['$scope', '$state', function($scope, $state) {

                var init = function() {
                    $scope.scrollTo = angular.isDefined($scope.scrollTo) ? $scope.scrollTo : 0;
                };

                $scope.navigateToDuplicateView = function() {

                    if ($scope.onNavigateToDuplicateView) {
                        $scope.onNavigateToDuplicateView().then(function() {
                            $state.go('duplicates', { dataSource: $scope.notification.dataSource, forId: $scope.notification.notificationId });
                        });
                    } else {
                        $state.go('duplicates', { dataSource: $scope.notification.dataSource, forId: $scope.notification.notificationId });
                    }
                };

                init();
            }]
        };
    }]);