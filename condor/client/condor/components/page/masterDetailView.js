angular.module('inprotech.components.page').directive('ipMasterDetailView', function() {
    'use strict';
    return {
        scope: {},
        transclude: true,
        restrict: 'E',
        template: '<div><div ng-if="isMounted()" ng-show="visible()" ng-transclude></div> <div ng-if="showDetail" ui-view></div></div>',
        controller: function($scope, $attrs, $state, $timeout, hotkeyService, $transitions) {
            var state = $attrs.state;
            var isMounted = false;
            $scope.visible = function() {
                return $state.current.name === state || $state.current.name.split('-')[1] === state;
            };
            $scope.isMounted = function() {
                if (isMounted) {
                    return true;
                }

                isMounted = $state.current.name === state || $state.current.name.split('-')[1] === state;

                return isMounted;
            };

            $scope.$watch(function() {
                return $state.current.name;
            }, function() {
                if (!$scope.visible()) {
                    $timeout(function() {
                        $scope.showDetail = true;
                    }, 0);
                } else {
                    $scope.showDetail = false;
                }
            });

            var hotkeyBackup;
            //Backup hotkeys when navigating to detail page
            $transitions.onStart({}, function(trans) {
                var toState = trans.to();
                var fromState = trans.from();
                if (toState.name === fromState.name) {
                    return;
                }

                if (isParentState(fromState, toState) && $scope.visible()) {
                    hotkeyBackup = hotkeyService.clone();
                }
            });

            //Restore hotkeys when navigating to master page
            $transitions.onStart({}, function(trans) {
                var toState = trans.to();
                var fromState = trans.from();
                if (toState.name === fromState.name) {
                    return;
                }

                if (toState.name === state) {                    
                    hotkeyService.add(hotkeyBackup);
                    hotkeyBackup = null;
                }
            });

            function isParentState(state1, state2) {
                if (state1.name.length >= state2.name.length) {
                    return false;
                }

                return state2.name.substring(0, state1.name.length) === state1.name;
            }
        }
    };
});

