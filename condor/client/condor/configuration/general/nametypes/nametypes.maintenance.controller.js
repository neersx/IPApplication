angular.module('inprotech.configuration.general.nametypes')
    .controller('NameTypeMaintenanceController', NameTypeMaintenanceController);


function NameTypeMaintenanceController($uibModalInstance, notificationService, nameTypesService, states, hotkeys, modalService, options, $timeout) {
    'use strict';

    var vm = this;

    vm.entity = options.entity;
    vm.cancel = cancel;
    vm.save = save;
    vm.dismissAll = dismissAll;
    vm.isClassifiedChange = isClassifiedChange;
    vm.toggleSelection = toggleSelection;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.onPathNameTypeChanged = onPathNameTypeChanged;
    vm.onPathRelationshipChanged = onPathRelationshipChanged;
    vm.initShortcuts = initShortcuts;
    vm.disable = disable;
    vm.onChange = onChange;
    vm.launchNameTypesPriorityOrder = launchNameTypesPriorityOrder;
    vm.options = options;
    vm.errors = {};
    vm.getError = getError;
    vm.clearNameTypeCode = clearNameTypeCode;
    vm._isSaving = false;
    clearNameTypeCode();

    function disable() {
        return !(vm.maintenance.$dirty && vm.maintenance.$valid);
    }

    function clearNameTypeCode() {
        if (vm.entity.state === states.duplicating) {
            vm.entity.nameTypeCode = null;
        }
    }

    function cancel() {
        $uibModalInstance.dismiss('Cancel');
    }

    //This function validates the max field for ip-text-type. By default ip-text-field only works on text type.
    function onChange() {
        if (vm.entity.maximumAllowed && vm.entity.maximumAllowed > 999) {
            vm.maintenance.description.$setValidity('notSupportedValue', false);
        } else {
            vm.maintenance.description.$setValidity('notSupportedValue', true);
        }
    }

    function launchNameTypesPriorityOrder() {
        var dialog = modalService.openModal({
            launchSrc: 'maintenance',
            id: 'NameTypesOrder',
            controllerAs: 'vm'
        });
        dialog.then(function () {
            vm.options.searchCallbackFn();
        });
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
            nameTypesService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            nameTypesService.update(vm.entity)
                .then(afterSave, afterSaveError);
        }
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            nameTypesService.savedNameTypeIds.push(response.data.result.updatedId);
            $uibModalInstance.close();
            if (vm.entity.state === states.adding || vm.entity.state === states.duplicating) {
                $timeout(launchNameTypesPriorityOrder, 100);
            }
        } else {
            vm._isSaving = false;
            vm.errors = response.data.result.errors;
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: vm.getError('nameTypeCode').topic,
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

    function isClassifiedChange() {
        if (vm.entity.isClassified === true && vm.entity.state === states.updating) {
            notificationService.confirm({
                title: 'modal.sameNameType.title',
                message: 'modal.sameNameType.message'
            }).then(function () {
                vm.entity.addNameTypeClassification = true;
            });
        }
    }

    function toggleSelection(prop) {
        vm.entity[prop] = false;
    }

    function onPathNameTypeChanged() {
        if (vm.entity.pathNameTypePickList === null) {
            vm.entity.updateFromParentNameType = false;
            vm.entity.pathNameRelation = null;
            vm.entity.useHomeNameRelationship = false;
            vm.entity.useNameType = false;
        }
    }

    function onPathRelationshipChanged() {
        if (vm.entity.pathNameTypePickList === null) {
            vm.entity.useHomeNameRelationship = false;
            vm.entity.useNameType = false;
        }
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!disable() && modalService.canOpen('NameTypeMaintenance')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('NameTypeMaintenance')) {
                    vm.dismissAll();
                }
            }
        });
    }
}