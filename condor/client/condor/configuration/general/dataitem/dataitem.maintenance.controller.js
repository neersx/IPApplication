angular.module('inprotech.configuration.general.dataitem')
    .controller('DataItemMaintenanceConfigController', DataItemMaintenanceConfigController);

function DataItemMaintenanceConfigController(hotkeys, modalService, dataItemService, notificationService, $uibModalInstance, options, states, $translate) {
    var vm = this;

    vm.entity = {
        state: options.entity.state
    };
    vm.cancel = cancel;
    vm.save = save;
    vm.dismissAll = dismissAll;
    vm.disable = disable;
    vm.initShortcuts = initShortcuts;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.getError = getError;
    vm.form = {};
    vm.options = options;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.isEditState = isEditState;
    vm.isUpdated = false;

    clearDataItemName();
    initializeEntity();

    function clearDataItemName() {
        if (vm.entity.state === states.duplicating) {
            vm.options.entity.name = null;
        }
    }

    function initializeEntity() {
        if (options.dataItem && options.dataItem.id !== options.entity.id) {
            dataItemService.get(options.dataItem.id)
                .then(function (entity) {
                    vm.entity = entity;
                    vm.entity.state = states.updating;
                });
        } else {
            vm.entity = options.entity;
        }
    }

    function cancel() {
        $uibModalInstance.close({ dataItemId: vm.entity.id, shouldRefresh: vm.isUpdated });
    }

    function getError(field) {
        return _.find(vm.errors, function (error) {
            return error.field === field;
        });
    }

    function isEditState() {
        return vm.entity.state === states.updating;
    }

    function save() {
        vm.errors = null;
        if (vm.form.maintenance && vm.form.maintenance.$validate) {
            vm.form.maintenance.$validate();
        }
        if (vm.form.maintenance.$invalid) {
            return;
        }

        if (vm.entity.state === states.adding || vm.entity.state === states.duplicating) {
            dataItemService.add(vm.entity)
                .then(afterSave, afterSaveError);
        } else {
            if (vm.form.maintenance.code.$dirty) {
                var message = $translate.instant('dataItem.maintenance.editConfirmationMessage') + '<br/>' + $translate.instant('dataItem.maintenance.proceedConfirmation');
                notificationService.confirm({
                    message: message,
                    cancel: 'Cancel',
                    continue: 'Proceed'
                }).then(function () {
                    updateDataItem();
                });
            } else
                updateDataItem();
        }
    }

    function updateDataItem() {
        if (vm.entity.isSqlStatement) {
            vm.entity.sql.storedProcedure = null;
        } else {
            vm.entity.sql.sqlStatement = null;
        }
        dataItemService.update(vm.entity)
            .then(afterSave, afterSaveError);
    }

    function afterSave(response) {
        if (response.data.result === 'success') {
            dataItemService.savedDataItemIds.push(response.data.updatedId);
            if (vm.entity.state === states.updating) {
                vm.form.maintenance.$setPristine();
            } else {
                $uibModalInstance.close({ dataItemId: response.data.updatedId, shouldRefresh: true });
            }
            notificationService.success();
            vm.isUpdated = true;
        } else {
            vm.errors = response.data.errors;
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: response.data.errors[0].field === 'code' ? vm.getError(response.data.errors[0].field).topic : vm.getError(response.data.errors[0].field).message,
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        }
    }

    function afterSaveError(response) {
        notificationService.alert({
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.result.errors, {
                field: null
            })
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

    function disable() {
        return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid);
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (!disable() && modalService.canOpen('DataItemMaintenanceConfig')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('DataItemMaintenanceConfig')) {
                    vm.dismissAll();
                }
            }
        });
    }
}