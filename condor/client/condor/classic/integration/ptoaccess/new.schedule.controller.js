angular.module('Inprotech.Integration.PtoAccess')
    .controller('newScheduleController', NewScheduleController);

function NewScheduleController($scope, $http, knownValues, dataSourceMap, url, keyLinkMap, options, $uibModalInstance, notificationService, hotkeys, modalService, $translate) {
    'use strict';

    var vm = this;
    vm.errors = {};
    vm.form = {};
    vm.viewData = {};

    vm.recurrence = knownValues.recurrence;
    vm.cancel = cancel;
    vm.save = save;
    vm.dismissAll = dismissAll;
    vm.afterSave = afterSave;
    vm.afterSaveError = afterSaveError;
    vm.initShortcuts = initShortcuts;
    vm.disable = disable;
    vm.getError = getError;
    vm.hasUnsavedChanges = hasUnsavedChanges;
    vm.options = options;

    vm._isSaving = false;

    vm.schedule = {
        name: '',
        dataSource: '',
        continuousDuplicate: false
    };

    vm.availableDataSources = [];

    vm.onSelectedDataSourceChanged = function (d) {
        vm.schedule.dataSource = !d ? '' : d.dataSource;
        vm.caseSourceTemplate = dataSourceMap.partial(vm.schedule.dataSource, 'caseSource');
        vm.downloadTypeTemplate = dataSourceMap.partial(vm.schedule.dataSource, 'downloadType');
        vm.schedule.isContinuousAvailable = dataSourceMap.partial(vm.schedule.dataSource, 'isContinuousAvailable');
        vm.schedule.recurrence = vm.schedule.isContinuousAvailable ? vm.recurrence.continuous : vm.recurrence.recurring;
        vm.sourceError = !d || !d.error ? null : d.error;
        if (vm.sourceError) {
            vm.errors = [{
                field: 'selectedDataSource',
                message: 'dataDownload.newSchedule.errors.' + vm.sourceError
            }];
        } else {
            vm.errors = null;
        }
        vm.errorLink = !d || !d.error ? null : keyLinkMap.getLinkFor(d.error, 'DataSource');
    }

    function disable() {
        return !(vm.form.maintenance.$dirty && vm.form.maintenance.$valid && !vm.sourceError && !vm.schedule.continuousDuplicate);
    }

    function cancel() {
        $uibModalInstance.close();
    }

    function save() {
        vm.schedule.continuousDuplicate = false;
        if (vm._isSaving) return;
        vm.errors = {};
        if (vm.form.maintenance && vm.form.maintenance.$validate) {
            vm.form.maintenance.$validate();
        }
        if (vm.form.maintenance.$invalid) {
            return;
        }
        vm._isSaving = true;

        $http.post(url.api('ptoaccess/newschedule/create'), vm.schedule)
            .then(afterSave, afterSaveError);
    }

    function afterSave(response) {
        var result = response.data.result.result;

        if (result === 'success') {
            $uibModalInstance.close();
            notificationService.success();
        } else {
            vm._isSaving = false;
            if (result === 'duplicate-schedule-name') {
                vm.errors = [{
                    field: 'name',
                    message: 'field.errors.notunique'
                }];
                return;
            }

            if (result === 'epo-missing-keys') {
                vm.errors = [{
                    field: 'selectedDataSource',
                    message: 'dataDownload.newSchedule.errors.epo-missing-keys'
                }];
                return;
            }

            if (result === 'duplicate-continuous') {
                vm.schedule.continuousDuplicate = true;
                return;
            }

            if (result === 'background-process-loginid') {
                vm.errors = [{
                    field: 'selectedDataSource',
                    message: 'dataDownload.newSchedule.errors.background-process-loginid'
                }];
                return;
            }

            notificationService.alert({
                title: 'modal.unableToComplete',
                message: vm.getError('description').topic,
                errors: _.where(result.errors, {
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
            return error.field == field;
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
                if (!disable() && modalService.canOpen('NewSchedule')) {
                    vm.save();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: function () {
                if (modalService.canOpen('NewSchedule')) {
                    vm.dismissAll();
                }
            }
        });
    }

    $http.get(url.api('ptoaccess/newScheduleview'))
        .then(function (response) {
            vm.viewData = response.data.result.viewData;
            vm.availableDataSources = _.map(vm.viewData.dataSources, function (ds) {
                return {
                    dataSource: ds.id,
                    name: $translate.instant('dataDownload.dataSource.' + ds.id),
                    dmsIntegrationEnabled: ds.dmsIntegrationEnabled,
                    error: ds.error
                };
            });
        });
}