angular.module('inprotech.configuration.rules.workflows')
    .controller('CreateEntriesController', function (viewData, workflowsMaintenanceEntriesService, modalService, $uibModalInstance, notificationService, hotkeys, $translate) {
        'use strict';

        var service = workflowsMaintenanceEntriesService;
        var vm = this;
        var insertAfterEntryId;
        
        vm.entryDescription = null;
        vm.initShortcuts = initShortcuts;
        vm.isSaveEnabled = isSaveEnabled;
        vm.resetUniqueError = resetUniqueError;
        vm.resetRequiredError = resetRequiredError;
        vm.save = save;
        vm.dismissAll = dismissAll;
        vm.events = viewData.selectedEvents;

        vm.criteriaId = viewData.criteriaId;
        vm.isSeparator = false;
        insertAfterEntryId = viewData.insertAfterEntryId;

        function save() {
            if (!isValid()) {
                return;
            }
            service.addEntryWorkflow(vm.criteriaId, vm.entryDescription, vm.isSeparator)
                .then(function (inherit) {
                    if (vm.events) {
                        var selectedEvents = _.pluck(vm.events, 'eventNo');
                        return service.addEntryEvents(vm.criteriaId, vm.entryDescription, selectedEvents, inherit);
                    } else {
                        return service.addEntry(vm.criteriaId, vm.entryDescription, vm.isSeparator, insertAfterEntryId, inherit);
                    }

                })
                .then(function (response) {
                    if (!response.data.error) {
                        afterSave(response.data);
                    } else {

                        if (response.data.error.field === 'entryDescription') {
                            vm.form.entryDescription.$setValidity(response.data.error.message, false);
                        }
                        notificationService.alert({
                            title: 'modal.unableToComplete',
                            message: $translate.instant('workflows.maintenance.entries.createEntry.errors.' + response.data.error.field + '.' + response.data.error.message)
                        });
                    }
                });
        }

        function isValid() {
            if (!vm.isSeparator && vm.entryDescription.trim() === '') {
                vm.form.entryDescription.$setValidity('required', false);
                return false;
            }

            return true;
        }

        function afterSave(data) {
            notificationService.success();
            $uibModalInstance.close(data);
        }

        function dismissAll() {
            if (!vm.entryDescription) {
                $uibModalInstance.close();
                return;
            }

            notificationService.discard()
                .then(function () {
                    $uibModalInstance.close();
                });
        }

        function isSaveEnabled() {
            return !vm.form.entryDescription.$invalid && vm.entryDescription;
        }

        function resetUniqueError() {
            vm.form.entryDescription.$setValidity('notunique', null);
        }

        function resetRequiredError() {
            vm.form.entryDescription.$setValidity('required', null);
        }

        function initShortcuts() {
            hotkeys.add({
                combo: 'alt+shift+s',
                description: 'shortcuts.save',
                callback: function () {
                    if (isSaveEnabled() && modalService.canOpen('CreateEntries')) {
                        vm.save();
                    }
                }
            });
            hotkeys.add({
                combo: 'alt+shift+z',
                description: 'shortcuts.revert',
                callback: function () {
                    if (modalService.canOpen('CreateEntries')) {
                        vm.dismissAll();
                    }
                }
            });
        }
    });