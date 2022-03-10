angular.module('inprotech.components.modal').component('ipMaintenanceModalHeader', {
    templateUrl: 'condor/components/modalservice/maintenance-modal-header.html',
    restrict: 'E',
    bindings: {
        pageTitle: '@',
        isAddAnother: '=',
        isEditMode: '<',
        onApply: '&',
        dismiss: '&',
        isApplyEnabled: '&',
        hasUnsavedChanges: '&'
    },
    controllerAs: 'vm',
    controller: function($scope, $attrs, notificationService, hotkeys) {
        'use strict';
        var vm = this;

        vm.doClose = function() {
            if (vm.hasUnsavedChanges()) {
                return notificationService.discard().then(function() {
                    vm.dismiss();
                });
            }

            vm.dismiss();
        };

        $scope.showSave = ($attrs.buttonMode && $attrs.buttonMode === 'save');
        $scope.showApply = (!$attrs.buttonMode || $attrs.buttonMode === 'apply');

        $scope.$on('modal.closing', function(evt, evtName) {
            if (evtName === 'escape key press') {
                evt.preventDefault();
                vm.doClose();
            }
        });

        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.apply',
            callback: function() {
                if (vm.isApplyEnabled()) {
                    vm.onApply();
                }
            }
        });
    }
});
