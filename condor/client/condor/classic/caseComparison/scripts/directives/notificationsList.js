angular.module('Inprotech.CaseDataComparison')
    .directive('notificationsList', ['url', 'comparisonDataSourceMap', '$timeout', function(url, comparisonDataSourceMap, $timeout) {
        'use strict';

        return {
            restrict: 'E',
            replace: true,
            transclude: true,
            scope: {
                notifications: '=',
                hasMore: '=?',
                isLoaded: '=?',
                currentSelection: '=?',
                initialSelection: '=?',
                showView: '&',
                loadMore: '&'
            },
            templateUrl: url.of('caseComparison/notifications-list.html'),
            link: function(scope) {
                $timeout(function() {
                    if ((scope.initialSelection || null) !== null) {
                        scope.selectAndShowView(scope.initialSelection);
                    }
                }, 1000);
            },
            controller: ['$scope', function($scope) {

                var init = function() {
                    $scope.isLoaded = angular.isDefined($scope.isLoaded) ? $scope.isLoaded : true;

                    $scope.hasMore = angular.isDefined($scope.hasMore) ? $scope.hasMore : false;
                };

                $scope.getSourceName = function(sourceId) {
                    return comparisonDataSourceMap.name(sourceId);
                };

                $scope.selectAndShowView = function(n) {
                    $scope.currentSelection = n;

                    $scope.showView({ notification: n });
                };

                init();
            }]
        };
    }]);