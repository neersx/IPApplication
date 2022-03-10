angular.module('inprotech.configuration.rules.workflows')
    .controller('DocumentsMaintenanceController', function ($scope, $uibModalInstance, $translate, notificationService, workflowsEventControlService, options, maintenanceModalService) {
        'use strict';
        var vm = this;
        var criteriaId;
        var isEditMode;
        var maintModalService;
        criteriaId = options.criteriaId;
        isEditMode = options.mode === 'edit';
        vm.canEdit = true;

        _.extend(vm, {
            isAddAnother: options.isAddAnother,
            title: isEditMode ? '.editTitle' : '.addTitle',
            isEditMode: isEditMode,
            criteriaId: criteriaId,
            addItem: options.addItem,
            allItems: options.allItems,
            eventId: options.eventId,
            eventDescription: options.eventDescription,
            currentItem: options.dataItem,
            formData: _.extend({
                produce: 'eventOccurs'
            }, options.dataItem),
            periodTypes: workflowsEventControlService.periodTypesShort,
            apply: apply,
            onNavigate: onNavigate,
            isApplyEnabled: isApplyEnabled,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges,
            isScheduledDisabled: isScheduledDisabled,
            onProduceChange: onProduceChange,
            onRecurringChange: onRecurringChange
        });
        maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        vm.recurring = Boolean((vm.formData.produce === 'asScheduled') &&
            (vm.formData.repeatEvery || (vm.formData.stopTime && vm.formData.stopTime.value)));

        function isScheduledDisabled() {
            return vm.formData.produce !== 'asScheduled';
        }

        function onProduceChange() {
            if (vm.isScheduledDisabled()) {
                vm.formData.startBefore = null;
                vm.recurring = false;
                vm.formData.repeatEvery = null;
                vm.formData.stopTime = null;
                vm.formData.maxDocuments = null;
            }
        }

        function onRecurringChange(isRecurring) {
            if (isRecurring) {
                vm.formData.repeatEvery = vm.formData.startBefore;
            } else {
                vm.formData.repeatEvery = null;
                vm.formData.stopTime = null;
                vm.formData.maxDocuments = null;
            }
        }

        function apply(keepOpen) {
            if (!vm.form.$validate()) {
                return false;
            }

            var data = _.clone(vm.formData);

            workflowsEventControlService.setEditedAddedFlags(data, isEditMode);
            maintModalService.applyChanges(data, options, isEditMode, vm.isAddAnother, keepOpen);

            return true;
        }

        function onNavigate() {
            if (vm.form.$pristine) {
                return true;
            }

            return apply(true);
        }

        function isApplyEnabled() {
            return workflowsEventControlService.isApplyEnabled(vm.form);
        }

        function hasUnsavedChanges() {
            return vm.form && vm.form.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }
    });