angular.module('inprotech.configuration.rules.workflows')
    .controller('DateComparisonMaintenanceController', function ($scope, $uibModalInstance, $translate, notificationService, workflowsEventControlService, options, dateHelper, maintenanceModalService) {
        'use strict';

        var vm = this;
        var criteriaId = options.criteriaId;
        var isEditMode = options.mode === 'edit';        

        var dataItem = _.extend({
            eventADate: 'Event',
            eventBDate: 'Event'
        }, options.dataItem);

        if (dataItem.compareDate) {
            dataItem.compareDate = dateHelper.convertForDatePicker(dataItem.compareDate);
        }

        _.extend(vm, {
            isAddAnother: options.isAddAnother,
            title: isEditMode ? '.editTitle' : '.addTitle',
            isEditMode: isEditMode,
            criteriaId: criteriaId,
            eventId: options.eventId,
            eventDescription: options.eventDescription,
            relativeCycles: workflowsEventControlService.relativeCycles,
            operators: workflowsEventControlService.operators,
            currentItem: options.dataItem,
            addItem: options.addItem,
            allItems: options.allItems,
            formData: dataItem,
            eventPicklistScope: workflowsEventControlService.initEventPicklistScope({
                criteriaId: criteriaId,
                filterByCriteria: true
            }),
            comparisonType: getComparisonType(dataItem),
            showEventB: false,
            showDate: false,
            showComparisonTypes: false,
            onEventAChange: onEventAChange,
            onComparisonOperatorChanged: onComparisonOperatorChanged,
            onEventBChange: onEventBChange,
            onComparisonTypeChange: onComparisonTypeChange,
            apply: apply,
            onNavigate: onNavigate,
            isApplyEnabled: isApplyEnabled,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges
        });

        var maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        onComparisonOperatorChanged();

        function apply(keepOpen) {
            if (!vm.form.$validate()) {
                return false;
            }

            var data = _.clone(vm.formData);

            if (vm.showComparisonTypes) {
                if (vm.comparisonType === 'eventB' || vm.comparisonType === 'systemDate') {
                    data.compareDate = null;
                }

                if (vm.comparisonType === 'date' || vm.comparisonType === 'systemDate') {
                    data.eventB = null;
                    data.eventBDate = null;
                    data.eventBRelativeCycle = null;
                    data.compareRelationship = null;
                }

                data.compareSystemDate = vm.comparisonType === 'systemDate';

            } else {
                data.eventB = null;
                data.eventBDate = null;
                data.eventBRelativeCycle = null;
                data.compareRelationship = null;

                data.compareDate = null;

                data.compareSystemDate = null;
            }


            if (workflowsEventControlService.isDuplicated(_.without(options.allItems, options.dataItem), data, ['eventA', 'eventADate', 'eventARelativeCycle', 'comparisonOperator', 'eventB', 'eventBDate', 'eventBRelativeCycle', 'compareRelationship', 'compareDate'])) {
                notificationService.alert({
                    message: $translate.instant('workflows.eventcontrol.dateComparison.maintenance.duplicate')
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

        function onEventAChange() {
            if (!vm.formData.eventA) {
                return;
            }
            vm.formData.eventARelativeCycle = getDefaultRelativeCycle(vm.formData.eventA.maxCycles);
        }

        function onEventBChange() {
            if (!vm.formData.eventB) {
                return;
            }
            vm.formData.eventBRelativeCycle = getDefaultRelativeCycle(vm.formData.eventB.maxCycles);
        }

        function getDefaultRelativeCycle(maxCycles) {
            if (maxCycles > 1) {
                return 0; // current cycle
            }
            return 3; // cycle 1
        }

        function onComparisonOperatorChanged() {
            vm.showComparisonTypes = !vm.formData.comparisonOperator || (vm.formData.comparisonOperator.key !== 'EX' && vm.formData.comparisonOperator.key !== 'NE');
            onComparisonTypeChange();
        }

        function onComparisonTypeChange() {
            vm.showEventB = vm.showComparisonTypes && vm.comparisonType == 'eventB';
            vm.showDate = vm.showComparisonTypes && vm.comparisonType == 'date';
            if (vm.showEventB && !vm.formData.eventBDate) {
                vm.formData.eventBDate = 'Event';
            }
        }

        function getComparisonType(dataItem) {
            if (dataItem.compareDate) {
                return 'date';
            }

            if (dataItem.compareSystemDate) {
                return 'systemDate';
            }

            return 'eventB';
        }

        function hasUnsavedChanges() {
            return vm.form && vm.form.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }
    });