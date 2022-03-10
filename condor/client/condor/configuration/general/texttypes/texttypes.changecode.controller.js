angular.module('inprotech.configuration.general.texttypes')
    .controller('ChangeTextTypeCodeController', ChangeTextTypeCodeController);


function ChangeTextTypeCodeController($uibModalInstance, notificationService, textTypesService, hotkeys, modalService, options) {
    'use strict';

    var vm = this;

    vm.cancel = cancel;
    vm.save = save;
    vm.dismissAll = dismissAll;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.initShortcuts = initShortcuts;
    vm.errors = {};
    vm.getError = getError;
    vm.formValid = formValid;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.entity = options.entity;

    function formValid() {
        return (vm.changeCodeForm.newTextTypeCode && vm.changeCodeForm.newTextTypeCode.$dirty && vm.changeCodeForm.newTextTypeCode.$valid)
    }

    function cancel() {
        $uibModalInstance.close();
    }

    function save(client) {
        vm.errors = {};
        if (client.$invalid) {
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'modal.alert.unsavedchanges'
            });
            return;
        }
        textTypesService.changeTextTypeCode(vm.entity)
            .then(afterSave, afterSaveError);
    }

    function afterSave(response) {
        if (response.data.result.result === 'success') {
            textTypesService.savedTextTypeIds.push(response.data.result.updatedId);
            $uibModalInstance.close();
            notificationService.success();
        } else {
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
        notificationService.alert({
            title: 'modal.unableToComplete',
            message: 'modal.alert.unsavedchanges',
            errors: _.where(response.data.result.errors, {
                field: null
            })
        });
    }

    function getError(field) {
        return _.find(vm.errors, function (error) {
            return error.field == field;
        })
    }

    function hasUnsavedChanges() {
        return vm.changeCodeForm.$dirty;
    }

    function dismissAll(client) {
        if (!client.$dirty) {
            vm.cancel();
            return;
        }

        notificationService.discard()
            .then(function () {
                vm.cancel();
            });
    }

    function initShortcuts(form) {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (formValid() && modalService.canOpen('ChangeTextTypeCode')) {
                    vm.save(form);
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('ChangeTextTypeCode')) {
                    vm.dismissAll(form);
                }
            }
        });
    }
}