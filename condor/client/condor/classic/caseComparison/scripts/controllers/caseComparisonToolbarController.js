angular.module('Inprotech.CaseDataComparison')
    .controller('caseComparisonToolbarController', [
        '$scope', 'http', 'url', 'comparisonData', 'notificationService',
        function($scope, http, url, comparisonData, notificationService) {
            'use strict';

            $scope.notification = null;

            function init(notification) {
                $scope.saveState = null;
                comparisonData.setNotification($scope.notification = notification);
                $scope.isComparisonData = notification && notification.type === 'case-comparison';
            }

            $scope.shouldHideToolbar = function() {
                return $scope.notification && $scope.notification.type === 'rejected';
            };

            $scope.canMarkReviewed = function() {
                if (!$scope.notification) {
                    return false;
                }

                if ($scope.notification.isReviewed) {
                    return false;
                }

                if ($scope.notification.type === 'rejected') {
                    return false;
                }

                if ($scope.notification.type === 'new-case') {
                    return false;
                }

                if ($scope.notification.type === 'error') {
                    return true;
                }

                return $scope.updateable();
            };

            $scope.saveable = function() {
                /* has differences to be saved */
                return comparisonData.saveable();
            };

            $scope.updateable = function() {
                return comparisonData.updateable();
            };

            $scope.markReviewed = function() {
                if ($scope.notification.isReviewed !== true && $scope.notification.notificationId) {
                    http.post(url.api('casecomparison/inbox/review?notificationId=' + $scope.notification.notificationId + '&isReviewed=' + true))
                        .success(function() {
                            $scope.notification.isReviewed = true;
                            notificationService.success('caseComparisonInbox.markedReviewed');
                        });
                }
            };

            $scope.saveChanges = function() {
                comparisonData.saveChanges($scope);
            };

            $scope.quickMarkReviewed = function() {
                if ($scope.canMarkReviewed() && !$scope.saveable()) {
                    $scope.markReviewed();
                }
            };

            $scope.quickSaveChanges = function() {
                if ($scope.saveable()) {
                    $scope.saveChanges();
                }
            };

            $scope.quickSelectAll = function() {
                comparisonData.selectAllDiffs();
            };

            $scope.$on('case-comparison-updated', function() {
                if (comparisonData.areAllDifferencesSelected()) {
                    $scope.markReviewed();
                }
            });

            var notificationselectionChanged = function(evt, notification) {
                init(notification);
            };

            $scope.$on('rejected', notificationselectionChanged);
            $scope.$on('case-comparison', notificationselectionChanged);
            $scope.$on('error', notificationselectionChanged);
            $scope.$on('new-case', notificationselectionChanged);

            $scope.initialInit = function(notification) {
                if (notification) {
                    notificationselectionChanged(null, notification);
                }
            };
        }
    ]);