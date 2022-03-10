angular.module('inprotech.configuration.rules.workflows')
    .controller('RemindersMaintenanceController', function ($scope, $uibModalInstance, $translate, notificationService, workflowsEventControlService, options, maintenanceModalService) {
        'use strict';
        var vm = this;
        var maintModalService;
        var criteriaId;
        var isEditMode;

        criteriaId = options.criteriaId;
        isEditMode = options.mode === 'edit';

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
                sendToStaff: true,
                sendToSignatory: true,
                repeatEvery: null
            }, options.dataItem),
            periodTypes: workflowsEventControlService.periodTypesShort,
            apply: apply,
            onNavigate: onNavigate,
            warningOnNegativeNumber: warningOnNegativeNumber,
            isApplyEnabled: isApplyEnabled,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges,
            onRecurringChange: onRecurringChange,
            clearRelationship: clearRelationship,
            isRelationshipDisabled: isRelationshipDisabled,
            isUseAlternateMessageDisabled: isUseAlternateMessageDisabled
        });
        maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        vm.recurring = Boolean(vm.formData.repeatEvery || (vm.formData.stopTime && vm.formData.stopTime.value));

        function onRecurringChange(isRecurring) {
            if (isRecurring) {
                vm.formData.repeatEvery = vm.formData.startBefore;
            } else {
                vm.formData.repeatEvery = null;
                vm.formData.stopTime = null;
            }
        }

        function warningOnNegativeNumber(fieldname) {
            if (vm.formData.startBefore) {
                if (vm.formData.startBefore[fieldname] < 0) {
                    return "workflows.eventcontrol.dueDateCalc.maintenance.startSendingWarning";
                } else {
                    return null;
                }
            }
        }

        function atLeastOneRecipient() {
            if (
                vm.formData.sendToStaff ||
                vm.formData.sendToSignatory ||
                vm.formData.sendToCriticalList ||

                vm.formData.name ||
                vm.formData.nameTypes
            ) {
                return true;
            }
            return false;
        }

        function apply(keepOpen) {
            if (!vm.form.$validate() || !vm.form.$dirty) {
                return false;
            }
            var data = _.clone(vm.formData);

            if (!atLeastOneRecipient()) {
                notificationService.alert({
                    title: $translate.instant('modal.unableToComplete'),
                    message: $translate.instant('workflows.eventcontrol.reminders.maintenance.atLeastSelected.content')
                });
                return false;
            }

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

        function clearRelationship() {
            if (!vm.formData.nameTypes && !vm.formData.name) {
                vm.formData.relationship = null;
            }
        }

        function isRelationshipDisabled() {
            return (!vm.formData.nameTypes || vm.formData.nameTypes.length == 0) && !vm.formData.name;
        }

        function isUseAlternateMessageDisabled() {
            var disable = vm.formData.alternateMessage == null || vm.formData.alternateMessage.length == 0;

            if (disable) {
                vm.formData.useOnAndAfterDueDate = false;
            }

            return disable;
        }
    });