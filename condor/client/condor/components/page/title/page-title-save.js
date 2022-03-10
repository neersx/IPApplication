angular.module('inprotech.components.page').directive('ipPageTitleSave', function() {
    'use strict';

    return {
        restrict: 'EA',
        transclude: true,
        scope: {
            pageTitle: '@',
            pageSubtitle: '@',
            onSave: '&',
            onDiscard: '&',
            onDelete: '&?',
            isSaveEnabled: '&',
            isDiscardEnabled: '&',
            isDeleteEnabled: '&?',
            isDiscardAvailable: '&?',
            isSaveAvailable: '&?'
        },
        templateUrl: 'condor/components/page/title/page-title-save.html',
        controller: function($scope, hotkeys, notificationService) {
            $scope.doDiscard = function() {
                return notificationService.discard().then(function() {
                    $scope.onDiscard();
                });
            };

            $scope.isDeleteAvailable = _.isFunction($scope.onDelete) && _.isFunction($scope.isDeleteEnabled);
            $scope.isDiscardAvailableInternal = _.isFunction($scope.isDiscardAvailable) ? $scope.isDiscardAvailable() : true;
            $scope.isSaveAvailableInternal = _.isFunction($scope.isSaveAvailable) ? $scope.isSaveAvailable() : true;

            initShortcuts();

            function initShortcuts() {
                hotkeys.add({
                    combo: 'alt+shift+s',
                    description: 'shortcuts.save',
                    callback: function() {
                        if ($scope.isSaveEnabled()) {
                            $scope.onSave();
                        }
                    }
                });

                hotkeys.add({
                    combo: 'alt+shift+z',
                    description: 'shortcuts.revert',
                    callback: function() {
                        if ($scope.isDiscardEnabled()) {
                            $scope.doDiscard();
                        }
                    }
                });
            }
        }
    };
});