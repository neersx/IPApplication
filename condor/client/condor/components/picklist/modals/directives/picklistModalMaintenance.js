angular.module('inprotech.components.picklist').directive('ipPicklistModalMaintenance', function() {
    'use strict';

    return {
        restrict: 'E',
        scope: false,
        templateUrl: 'condor/components/picklist/modals/directives/picklistModalMaintenance.html',
        controller: function($scope, hotkeys) {
            var vm = $scope.vm;
            hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function() {
                    if (vm.currentView === 'maintenance' && vm.isSaveEnabled()) {
                        vm.save();
                    }
                }
            });

            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.discard',
                callback: function() {
                    if (vm.currentView === 'maintenance') {
                        vm.abandon();
                        return false;
                    } else {
                        return true;
                    }
                }
            });
        }
    };
});
