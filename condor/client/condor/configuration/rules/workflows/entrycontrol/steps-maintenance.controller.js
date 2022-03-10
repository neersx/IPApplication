angular.module('inprotech.configuration.rules.workflows')
    .controller('EntryStepsMaintenanceController', function ($uibModalInstance, $translate, notificationService, workflowsEntryControlService, workflowsEntryControlStepsService, options, $scope, maintenanceModalService) {
        'use strict';

        var vm = this;
        var maintModalService;
        var stepService;
        var criteriaId;
        var isEditMode;

        stepService = workflowsEntryControlStepsService;
        criteriaId = options.criteriaId;
        isEditMode = options.mode === 'edit';

        _.extend(vm, {
            isAddAnother: options.isAddAnother,
            editItem: options.editItem,
            title: isEditMode ? '.editTitle' : '.addTitle',
            criteriaId: criteriaId,
            criteriaCharacteristics: options.criteriaCharacteristics,
            entryId: options.entryId,
            entryDescription: options.entryDescription,
            formData: angular.copy(options.dataItem) || {},
            isApplyEnabled: isApplyEnabled,
            apply: apply,
            onNavigate: onNavigate,
            isEditMode: isEditMode,
            onStepTypeChanged: onStepTypeChanged,
            hasUnsavedChanges: hasUnsavedChanges,
            currentItem: options.dataItem,
            addItem: options.addItem,
            allItems: options.all,
            dismiss: dismiss
        });
        maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        function apply(keepOpen) {
            if (!vm.form.$validate()) {
                return false;
            }

            if (isDuplicate(vm.formData)) {
                return false;
            }

            var data = _.clone(vm.formData);
            data.error = null;
            data.errorMessage = null;

            if (isEditMode) {
                vm.editItem(options.dataItem, data);
            }

            workflowsEntryControlService.setEditedAddedFlags(data, isEditMode);
            maintModalService.applyChanges(data, options, isEditMode, vm.isAddAnother, keepOpen);

            return true;
        }

        function onNavigate() {
            if (vm.form.$pristine) {
                return true;
            }

            return apply(true);
        }

        function isDuplicate(data) {
            var dataToConsider = isEditMode ? _.without(options.all, options.dataItem) : options.all;
            var duplicateRecords = _.chain(dataToConsider)
                .filter(function (s) {
                    return stepService.areStepsSame(this.newStep, s);
                }, {
                    newStep: data
                }).value();

            var result = duplicateRecords.length > 0;

            if (result) {
                notificationService.alert({
                    message: $translate.instant('workflows.entrycontrol.steps.maintenance.duplicate'),
                    title: $translate.instant('modal.unableToComplete')
                });
            }

            return result;
        }

        function onStepTypeChanged() {
            stepService.checkStepCategories(vm.formData);
            vm.formData.title = vm.formData.step.value;
        }

        function isApplyEnabled() {
            return workflowsEntryControlService.isApplyEnabled(vm.form);
        }

        function hasUnsavedChanges() {
            return vm.form && vm.form.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }
    });