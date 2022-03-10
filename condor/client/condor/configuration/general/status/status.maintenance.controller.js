angular.module('inprotech.configuration.general.status')
    .controller('StatusMaintenanceController', StatusMaintenanceController);


function StatusMaintenanceController($uibModalInstance, notificationService, statusService, states, hotkeys, modalService, options) {
    'use strict';

    var vm = this;

    vm.entity = options.entity;
    vm.supportData = options.supportData;
    vm.cancel = cancel;
    vm.dismissAll = dismissAll;
    vm.save = save;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.toggleSelections = toggleSelections;
    vm.initShortcuts = initShortcuts;
    vm.disable = disable;
    vm.errors = {};
    vm.getError = getError;
    vm._isSaving = false;

    function disable() {
        return !(vm.maintenance.$dirty && vm.maintenance.$valid);
    }

    function cancel() {
        $uibModalInstance.dismiss('Cancel');
    }

    function dismissAll() {
        if (!vm.maintenance.$dirty) {
            vm.cancel();
            return;
        }

        notificationService.discard()
            .then(function () {
                vm.cancel();
            });
    }

    function toggleSelections(arr) {
        _.each(arr, function (prop) {
            vm.entity[prop] = false;
        });
    }

    function addSavedStatus(updatedId) {
        statusService.savedStatusIds.push(updatedId);
    }

    function save() {
        if (vm._isSaving) return;
        vm.errors = {};

        if (vm.maintenance && vm.maintenance.$validate) {
            vm.maintenance.$validate();
        }

        if (vm.maintenance.$invalid) {
            return;
        }
        vm._isSaving = true;
        if (vm.entity.state === states.adding || vm.entity.state === states.duplicating) {
            statusService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            statusService.update(vm.entity)
                .then(afterSave, afterSaveError);
        }
    }

    function afterSave(response) {
        if (response.data.result === 'success') {
            addSavedStatus(response.data.updatedId);
            $uibModalInstance.close(vm.entity.statusType === 'renewal');
        } else {
            vm._isSaving = false;
            vm.errors = response.data.errors;
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: vm.getError('internalName').topic,
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        }
    }

    function afterSaveError(response) {
        vm._isSaving = false;
        vm.errors = response.data.errors;
        notificationService.alert({
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.errors, {
                field: null
            })
        });
    }

    function getError(field) {
        return _.find(vm.errors, function (error) {
            return error.field === field;
        });
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!disable() && modalService.canOpen('StatusMaintenance')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('StatusMaintenance')) {
                    vm.dismissAll();
                }
            }
        });
    }
}