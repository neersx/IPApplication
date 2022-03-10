angular.module('Inprotech.CaseDataComparison')
    .controller('duplicatesController', [
        '$scope', 'viewInitialiser', '$stateParams', '$state', 'inboxState',
        function($scope, viewInitialiser, $stateParams, $state, inboxState) {
            'use strict';

            $scope.showView = function(notification) {
                $scope.detailView = notification;

                if (notification) {
                    $scope.$broadcast(notification.type, notification);
                } else {
                    $scope.$broadcast('error', null);
                }
            };

            $scope.init = function() {
                $scope.canUpdateCase = viewInitialiser.viewData.canUpdateCase;
                var duplicates = viewInitialiser.viewData.duplicates;

                //Make sure notification in question is the first element in the list
                var idInQuestion = Number($stateParams.forId);
                if (!isNaN(idInQuestion)) {
                    var nInQuestion = _.findWhere(duplicates, { notificationId: idInQuestion });
                    if (nInQuestion) {
                        duplicates = _.without(duplicates, nInQuestion);
                        duplicates.splice(0, 0, nInQuestion);
                    }
                }

                $scope.duplicates = duplicates;

                if ($scope.duplicates.length > 0) {
                    $scope.showView(_.first($scope.duplicates));
                }
            };

            $scope.$on('case-match-rejection', function(evt, data) {
                var index = _.findIndex($scope.duplicates, $scope.detailView);
                $scope.duplicates[index] = data;
                $scope.showView(data);
            });

            $scope.$on('case-match-rejection-reversed', function(evt, data) {
                var index = _.findIndex($scope.duplicates, $scope.detailView);
                $scope.duplicates[index] = data;
                $scope.showView(data);
            });

            $scope.navigateToInbox = function() {
                inboxState.updateState($scope.duplicates);

                $state.go('inbox', { restore: true });
            }
        }
    ]);