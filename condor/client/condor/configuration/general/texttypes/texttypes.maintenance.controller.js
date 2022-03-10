angular.module('inprotech.configuration.general.texttypes')
    .controller('TextTypeMaintenanceController', TextTypeMaintenanceController);


function TextTypeMaintenanceController($scope, $uibModalInstance, notificationService, textTypesService, states, hotkeys, modalService, options) {
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
    vm.getError = getError;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.isEditState = isEditState;
    vm.onUsedByNameChange = onUsedByNameChange;
    vm.validateCheckboxes = validateCheckboxes
    vm.clearTextTypeCode = clearTextTypeCode;
    vm._isSaving = false;
    clearTextTypeCode();

    initializeEntity();

    function initializeEntity() {
        if (options.dataItem != null && options.dataItem.id != options.entity.id) {
            textTypesService.get(options.dataItem.id)
                .then(function (entity) {
                    vm.entity = entity;
                    vm.entity.state = states.updating;
                });
        } else {
            vm.entity = options.entity;
        }
    }

    function clearTextTypeCode() {
        if (vm.entity.state === states.duplicating) {
            vm.options.entity.id = null;
        }
    }

    function isEditState() {
        return vm.entity != null && vm.entity.state === states.updating;
    }

    function disable() {
        return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid && vm.validateCheckboxes());
    }

    function validateCheckboxes() {
        return (!vm.entity.usedByName || (vm.entity.usedByName && (vm.entity.usedByEmployee || vm.entity.usedByIndividual || vm.entity.usedByOrganisation)));
    }

    function onUsedByNameChange() {
        if (!vm.entity.usedByName) {
            vm.entity.usedByEmployee = false;
            vm.entity.usedByIndividual = false;
            vm.entity.usedByOrganisation = false;
        }
    }

    function cancel() {
        $uibModalInstance.close();
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
            textTypesService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            textTypesService.update(vm.entity)
                .then(afterSave, afterSaveError);
        }
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            textTypesService.savedTextTypeIds.push(response.data.result.updatedId);
            if (vm.entity.state === states.updating) {
                vm._isSaving = false;
                vm.form.maintenance.$setPristine();
            } else {
                $uibModalInstance.close();
            }
            notificationService.success();
        } else {
            vm._isSaving = false;
            vm.errors = response.data.result.errors;
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: vm.getError('textTypeCode').topic,
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
            return error.field == field
        })
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
                if (!disable() && modalService.canOpen('TextTypeMaintenance')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('TextTypeMaintenance')) {
                    vm.dismissAll();
                }
            }
        });
    }
}