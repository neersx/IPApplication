angular.module('Inprotech.CaseDataComparison')
    .controller('caseComparisonOtherToolbarController', [
        '$rootScope', '$scope', 'http', 'url', 'comparisonData', 'notificationService',
        function($rootScope, $scope, http, url, comparisonData, notificationService) {
            'use strict';

            $scope.notification = null;

            function init(notification) {
                $scope.saveState = null;
                comparisonData.setNotification($scope.notification = notification);
                $scope.isComparisonData = notification && notification.type === 'case-comparison';
            }

            $scope.canUndoRejectMatch = function() {
                if ($scope.updateable() && $scope.notification && $scope.notification.type === 'rejected') {
                    return true;
                }

                return false;
            };

            $scope.canRejectMatch = function() {
                if (!$scope.notification) {
                    return false;
                }

                if ($scope.notification.type === 'rejected') {
                    return false;
                }

                if ($scope.notification.type === 'new-case') {
                    return false;
                }

                if ($scope.notification.type === 'error') {
                    return false;
                }

                return $scope.updateable() && comparisonData.rejectable();
            };

            $scope.saveable = function() {
                /* has differences to be saved */
                return comparisonData.saveable();
            };

            $scope.updateable = function() {
                return comparisonData.updateable();
            };

            $scope.undoRejectCaseMatch = function() {
                if ($scope.saveState === 'reset-reject') {
                    return;
                }

                if ($scope.canUndoRejectMatch() === true) {
                    $scope.saveState = 'reset-reject';

                    http.post(url.api('casecomparison/inbox/reverse-case-match-rejection?notificationId=' + $scope.notification.notificationId))
                        .success(function(data) {
                            notificationService.success('caseComparisonInbox.caseMatchRejectUndone');
                            $rootScope.$broadcast('case-match-rejection-reversed', data);
                        });
                }
            };

            $scope.rejectCaseMatch = function() {
                if ($scope.saveState === 'rejecting') {
                    return;
                }

                if ($scope.canRejectMatch() === true) {
                    $scope.saveState = 'rejecting';

                    http.post(url.api('casecomparison/inbox/reject-case-match?notificationId=' + $scope.notification.notificationId))
                        .success(function(data) {
                            notificationService.success('caseComparisonInbox.caseMatchReject');
                            $rootScope.$broadcast('case-match-rejection', data);
                        });
                }
            };

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