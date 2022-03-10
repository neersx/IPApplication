angular.module('inprotech.configuration.rules.workflows')
    .controller('DueDateCalcMaintenanceController', function ($scope, $uibModalInstance, $translate, notificationService, workflowsEventControlService, options, maintenanceModalService) {
        'use strict';
        var vm = this;
        var criteriaId = options.criteriaId;
        var isEditMode = options.mode === 'edit';
        vm.setDocumentGenerationCompatibility = setDocumentGenerationCompatibility;

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
                fromTo: 1,
                operator: 'A',
                reminderOption: 'standard'
            }, options.dataItem),
            periodTypes: workflowsEventControlService.periodTypes,
            relativeCycles: workflowsEventControlService.relativeCycles,
            adjustByOptions: options.adjustByOptions,
            nonWorkDayOptions: workflowsEventControlService.nonWorkDayOptions,
            apply: apply,
            onNavigate: onNavigate,
            isApplyEnabled: isApplyEnabled,
            eventPicklistScope: workflowsEventControlService.initEventPicklistScope({
                criteriaId: criteriaId,
                filterByCriteria: true
            }),
            isCycleDisabled: !options.isCyclic,
            isJurisdictionDisabled: !options.allowDueDateCalcJurisdiction,
            onFromEventChange: onFromEventChange,
            getAdjustByWarningText : getAdjustByWarningText,
            getPeriodWarningText: getPeriodWarningText,
            getToCycleWarningText: getToCycleWarningText,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges,
            isPeriodTextDisabled: isPeriodTextDisabled
        });
        vm.formData.cycle = vm.formData.cycle || 1;
        var maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        function apply(keepOpen) {
            if (!vm.form.$validate()) {
                return false;
            }

            var data = _.clone(vm.formData);

            if (workflowsEventControlService.isDuplicated(_.without(options.allItems, options.dataItem), data, ['cycle', 'jurisdiction', 'fromEvent', 'relativeCycle', 'period'])) {
                notificationService.alert({
                    message: $translate.instant('workflows.eventcontrol.dueDateCalc.maintenance.duplicate')
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

        function onFromEventChange() {
            if (!vm.formData.fromEvent) {
                return;
            }

            if (vm.formData.fromEvent.maxCycles > 1) {
                vm.formData.relativeCycle = 0; // current cycle
            } else {
                vm.formData.relativeCycle = 3; // cycle 1
            }
        }

        function getAdjustByWarningText() {
            return (vm.formData.adjustBy == '~0' && !options.standingInstructionCharacteristic) ?
                    'workflows.eventcontrol.dueDateCalc.maintenance.standingInstructionWarning' :
                    null;
        }

        function getToCycleWarningText(){
            return (vm.formData.cycle > options.maxCycles) ?
                    'workflows.eventcontrol.dueDateCalc.maintenance.toCycleWarning' :
                    null;
        }

        function getPeriodWarningText() {
            return (vm.formData.period &&
                    !options.standingInstructionCharacteristic &&
                    (vm.formData.period.type == '1' || vm.formData.period.type == '2' || vm.formData.period.type == '3')) ?
                    'workflows.eventcontrol.dueDateCalc.maintenance.standingInstructionWarning' :
                    null;
        }

        function setDocumentGenerationCompatibility(query) {
            return angular.extend({}, query, {
                options: {
                    legacy: true
                }
            });
        }

        function hasUnsavedChanges() {
            return vm.form && vm.form.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }

        function isPeriodTextDisabled(option) {
            var disabled = ['E', '1', '2', '3'].indexOf(option) !== -1;

            return disabled;
        }
    });