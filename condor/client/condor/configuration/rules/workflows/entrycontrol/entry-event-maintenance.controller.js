angular.module('inprotech.configuration.rules.workflows')
    .controller('EntryEventMaintenanceController', function ($uibModalInstance, $translate, notificationService, workflowsEntryControlService, options, $scope, maintenanceModalService) {
        'use strict';

        var maintModalService;
        var criteriaId;
        var isEditMode
        var vm = this;

        criteriaId = options.criteriaId;
        isEditMode = options.mode === 'edit';

        _.extend(vm, {
            isAddAnother: options.isAddAnother,
            title: isEditMode ? '.editTitle' : '.addTitle',
            criteriaId: criteriaId,
            entryId: options.entryId,
            entryDescription: options.entryDescription,
            dateOptions: workflowsEntryControlService.dateOptions,
            controlOptions: workflowsEntryControlService.controlOptions,
            dueDateRespOptions: workflowsEntryControlService.dueDateRespOptions(),
            formData: _.extend({
                eventDate: 3
            }, options.dataItem),
            eventPicklistScope: {
                criteriaId: criteriaId,
                filterByCriteria: true,
                extendQuery: extendQuery
            },
            isApplyEnabled: isApplyEnabled,
            apply: apply,
            onNavigate: onNavigate,
            hasUnsavedChanges: hasUnsavedChanges,
            dismiss: dismiss,
            isEditMode: isEditMode,
            currentItem: options.dataItem,
            addItem: options.addItem,
            allItems: options.all
        });
        maintModalService = maintenanceModalService($scope, $uibModalInstance, vm.addItem);

        function apply(keepOpen) {
            if (!vm.form.$validate()) {
                return false;
            }

            var data = _.clone(vm.formData);

            if (!isAtleastOneAttributeFilled(data) || isDuplicate(data)) {
                return false;
            }

            if (isEditMode && !data.isAdded) { // editing new row should still be marked as new
                data.isEdited = true;
                data.inherited = false;
            } else {
                data.isAdded = true;
            }

            if (isEditMode && !options.dataItem.previousEventId) {
                options.dataItem.previousEventId = options.dataItem.entryEvent.key;
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
            var isDuplicate = workflowsEntryControlService.isDuplicated(_.without(options.all, options.dataItem), data, ['entryEvent']);

            if (isDuplicate) {
                notificationService.alert({
                    message: $translate.instant('workflows.entrycontrol.details.maintenance.duplicate'),
                    title: $translate.instant('modal.unableToComplete')
                });
            }

            return isDuplicate;
        }

        function isAtleastOneAttributeFilled(data) {
            var allAttributeEmpty = data.eventDate == null && data.dueDate == null && data.period == null;
            if (allAttributeEmpty) {
                notificationService.alert({
                    message: $translate.instant('workflows.entrycontrol.details.maintenance.atleastOneCharacteristics'),
                    title: $translate.instant('modal.unableToComplete')
                });
            }
            return !allAttributeEmpty;
        }

        function isApplyEnabled() {
            return workflowsEntryControlService.isApplyEnabled(vm.form);
        }

        function extendQuery(query) {
            if (vm.eventPicklistScope.filterByCriteria) {
                return angular.extend({}, query, {
                    criteriaId: criteriaId,
                    picklistSearch: vm.eventPicklistScope.picklistSearch
                });
            }
            return angular.extend({}, query, {
                criteriaId: !vm.eventPicklistScope.picklistSearch ? criteriaId : null,
                picklistSearch: vm.eventPicklistScope.picklistSearch
            });
        }

        function hasUnsavedChanges() {
            return vm.form && vm.form.$dirty;
        }

        function dismiss() {
            $uibModalInstance.dismiss();
        }
    });