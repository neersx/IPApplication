angular.module('inprotech.configuration.general.jurisdictions')
    .controller('CreateJurisdictionController', function ($uibModalInstance, notificationService, jurisdictionMaintenanceService, jurisdictionsService, hotkeys) {
        'use strict';

        var vm = this;

        vm.cancel = cancel;
        vm.disable = disable;
        vm.dismissAll = dismissAll;
        vm.save = save;
        vm.getError = getError;
        vm.maintenance = {};
        vm.formData = {
            type: "0"
        };
        initShortcuts();

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }

        function disable() {
            return !(vm.maintenance.$dirty && vm.maintenance.$valid);
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

        function save() {
            if (vm.maintenance && vm.maintenance.$validate) {
                vm.maintenance.$validate();
            }
            if (vm.maintenance.$invalid) {
                return;
            }
            jurisdictionMaintenanceService.create(vm.formData).then(afterSave);
        }

        function afterSave(response) {
            if (response.data.result === 'success') {
                jurisdictionsService.newId = response.data.id;
                $uibModalInstance.close();
            } else {
                vm.errors = response.data.result.errors;
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: vm.getError('code').topic,
                    messageParams: {
                        id: vm.getError('code').id
                    },
                    errors: _.where(response.data.result.errors, {
                        field: null
                    })
                });
            }
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
                    if (!disable()) {
                        vm.save();
                    }
                }
            });
            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.close',
                callback: function () {
                    vm.dismissAll();
                }
            });
        }

    });
