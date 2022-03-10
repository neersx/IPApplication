angular.module('inprotech.configuration.general.numbertypes')
    .controller('NumberTypeMaintenanceController', NumberTypeMaintenanceController);


function NumberTypeMaintenanceController($uibModalInstance, notificationService, numberTypesService, states, hotkeys, modalService, options, $timeout) {
    'use strict';

    var vm = this;


    vm.entity = {
        state: options.entity.state
    };
    vm.cancel = cancel;
    vm.save = save;
    vm.dismissAll = dismissAll;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.initShortcuts = initShortcuts;
    vm.form = {};
    vm.disable = disable;
    vm.options = options;
    vm.errors = {};
    vm.launchNumberTypesPriorityOrder = launchNumberTypesPriorityOrder;
    vm.getError = getError;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.isEditState = isEditState;
    vm.clearNumberTypeCode = clearNumberTypeCode;
    vm._isSaving = false;
    clearNumberTypeCode();

    initializeEntity();

    function initializeEntity() {
        if (options.dataItem && options.dataItem.id !== options.entity.id) {
            numberTypesService.get(options.dataItem.id)
                .then(function (entity) {
                    vm.entity = entity;
                    vm.entity.state = states.updating;
                });
        } else {
            vm.entity = options.entity;
        }
    }

    function clearNumberTypeCode() {
        if (vm.entity.state === states.duplicating) {
            vm.options.entity.numberTypeCode = null;
        }
    }

    function isEditState() {
        return vm.entity.state === states.updating;
    }

    function disable() {
        return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid);
    }


    function cancel() {
        $uibModalInstance.close();
    }

    function launchNumberTypesPriorityOrder() {
        var dialog = modalService.openModal({
            launchSrc: 'maintenance',
            id: 'NumberTypesOrder',
            controllerAs: 'vm'
        });
        dialog.then(function () {
            vm.options.searchCallbackFn();
        });
    }

    function save() {
        if (vm._isSaving) return;
        vm.errors = {};
        if (vm.form.maintenance && vm.form.maintenance.$validate) {
            vm.form.maintenance.$validate();
        }
        if (vm.form.maintenance.$invalid) {
            return;
        }
        vm._isSaving = true;
        if (vm.entity.state === states.adding || vm.entity.state === states.duplicating) {
            numberTypesService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            numberTypesService.update(vm.entity)
                .then(afterSave, afterSaveError);
        }
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            numberTypesService.savedNumberTypeIds.push(response.data.result.updatedId);
            if (vm.entity.state === states.updating) {
                vm._isSaving = false;
                vm.form.maintenance.$setPristine();
            } else {
                $uibModalInstance.close();
                $timeout(launchNumberTypesPriorityOrder, 500);
            }
            notificationService.success();
        } else {
            vm._isSaving = false;
            vm.errors = response.data.result.errors;
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: vm.getError('numberTypeCode').topic,
                errors: _.where(response.data.result.errors, {
                    field: null
                })
            });
        }
    }

    function afterSaveError(response) {
        vm._isSaving = false;
        vm.errors = response.data.result.errors;
        notificationService.alert({
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.result.errors, {
                field: null
            })
        });
    }

    function getError(field) {
        return _.find(vm.errors, function (error) {
            return error.field === field;
        });
    }

    function hasUnsavedChanges() {
        return vm.form.maintenance.$dirty;
    }

    function dismissAll() {
        if (!vm.form.maintenance.$dirty) {
            vm.cancel();
            return;
        }

        notificationService.discard()
            .then(function () {
                vm.cancel();
            });
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!disable() && modalService.canOpen('NumberTypeMaintenance')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('NumberTypeMaintenance')) {
                    vm.dismissAll();
                }
            }
        });
    }
}