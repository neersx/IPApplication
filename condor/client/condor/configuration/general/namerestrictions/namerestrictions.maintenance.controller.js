angular.module('inprotech.configuration.general.namerestrictions')
    .controller('NameRestrictionsMaintenanceController', NameRestrictionsMaintenanceController)
    .constant('nameRestrictionActions', {
        DisplayWarningWithPassword: 2
    });


function NameRestrictionsMaintenanceController($uibModalInstance, notificationService, nameRestrictionsService, states, hotkeys, modalService, options, nameRestrictionActions) {
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
    vm.disable = disable;
    vm.getError = getError;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.entity = options.entity;
    vm.onActionChanged = onActionChanged;
    vm.isPasswordDisabled = isPasswordDisabled;
    vm.isEditState = isEditState;
    vm.options = options;
    vm._isSaving = false;
    initializeEntity();

    function initialize() {
        vm.errors = {};
        vm.form = {};
        vm.actionOptions = options.viewData;
        vm.selectedAction = getSelectedAction();
    }

    function initializeEntity() {
        initialize();
        if (options.dataItem && options.dataItem.id != options.entity.id) {
            nameRestrictionsService.get(options.dataItem.id)
                .then(function(entity) {
                    vm.entity = entity;
                    vm.entity.state = states.updating;
                    vm.selectedAction = getSelectedAction();
                });
        } else {
            vm.entity = options.entity;
        }
    }

    function isEditState() {
        return vm.entity.state === states.updating;
    }

    function getSelectedAction() {
        return _.find(options.viewData, function(item) {
            return item.type === vm.entity.action;
        });
    }

    function onActionChanged() {
        if (vm.selectedAction == null || vm.selectedAction.type !== nameRestrictionActions.DisplayWarningWithPassword) {
            vm.entity.password = null;
            vm.form.maintenance.password.$resetErrors();
        }
    }

    function isPasswordDisabled() {
        if (vm.selectedAction == null) {
            return true;
        }
        return vm.selectedAction.type !== nameRestrictionActions.DisplayWarningWithPassword;
    }

    function disable() {
        return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid);
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
        vm.entity.action = vm.selectedAction.type;
        if (vm.entity.state === states.adding || vm.entity.state === states.duplicating) {
            nameRestrictionsService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            nameRestrictionsService.update(vm.entity)
                .then(afterSave, afterSaveError);
        }
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            nameRestrictionsService.savedNameRestrictionIds.push(response.data.result.updatedId);
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
                message: vm.getError('description').topic,
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
        return _.find(vm.errors, function(error) {
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
            .then(function() {
                vm.cancel();
            });
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function() {
                if (!disable() && modalService.canOpen('NameRestrictionsMaintenance')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function() {
                if (modalService.canOpen('NameRestrictionsMaintenance')) {
                    vm.dismissAll();
                }
            }
        });
    }
}