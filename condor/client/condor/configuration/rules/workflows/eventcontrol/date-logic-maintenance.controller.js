angular.module('inprotech.configuration.rules.workflows')
    .controller('DateLogicMaintenanceController', function ($scope, $uibModalInstance, $translate, notificationService, workflowsEventControlService, options, maintenanceModalService) {
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
                appliesTo: 'Event',
                compareType: 'Event',
                ifRuleFails: 'Warn'
            }, options.dataItem),
            eventPicklistScope: workflowsEventControlService.initEventPicklistScope({
                criteriaId: criteriaId,
                filterByCriteria: true
            }),
            operators: workflowsEventControlService.dateLogicOperators,
            relativeCycles: workflowsEventControlService.relativeCycles,
            periodTypes: workflowsEventControlService.periodTypesShort,
            onComparisonEventChange: onComparisonEventChange,
            apply: apply,
            onNavigate: onNavigate,
            isApplyEnabled: isApplyEnabled,
            dismiss: dismiss,
            hasUnsavedChanges: hasUnsavedChanges
        });
        maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        function apply(keepOpen) {
            if (!vm.form.$validate() || !vm.form.$dirty) {
                return false;
            }
            var data = _.clone(vm.formData);

            if (workflowsEventControlService.isDuplicated(_.without(options.allItems, options.dataItem),
                data,
                ['appliesTo',
                    'operator',
                    'compareEvent',
                    'compareType',
                    'relativeCycle',
                    'caseRelationship',
                    'ifRuleFails'])) {
                notificationService.alert({
                    message: $translate.instant('workflows.eventcontrol.dateLogic.maintenance.duplicate')
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

        function onComparisonEventChange() {
            if (!vm.formData.compareEvent) {
                return;
            }

            if (vm.formData.compareEvent.maxCycles > 1) {
                vm.formData.relativeCycle = 0; // current cycle
            } else {
                vm.formData.relativeCycle = 3; // cycle 1
            }
        }
    });