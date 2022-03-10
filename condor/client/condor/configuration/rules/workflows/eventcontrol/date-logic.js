angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlDateLogic', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/date-logic.html',
    controllerAs: 'vm',
    bindings: {
        topic: '<'
    },
    controller: function ($scope, $translate, kendoGridBuilder, workflowsEventControlService, modalService, kendoGridService, hotkeys) {
        'use strict';

        var vm = this;
        var service;

        var viewData;
        var criteriaId;
        var eventId;
        var prefix;
        var maintenancePrefix;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService;

            viewData = vm.topic.params.viewData;
            criteriaId = viewData.criteriaId;
            eventId = viewData.eventId;
            prefix = 'workflows.eventcontrol.dateLogic.';
            maintenancePrefix = 'workflows.eventcontrol.dateLogic.maintenance.';

            vm.canEdit = viewData.canEdit;
            vm.gridOptions = buildGridOptions();
            vm.formatPicklistColumn = service.formatPicklistColumn;
            vm.formatAppliesTo = formatAppliesTo;
            vm.formatCompareType = formatCompareType;
            vm.formatRelativeCycle = formatRelativeCycle;
            vm.formatIfRuleFails = formatIfRuleFails;

            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;

            vm.topic.getFormData = getFormData;
            vm.topic.isDirty = isDirty;
            vm.topic.initializeShortcuts = initShortcuts;
        }

        function initShortcuts() {
            if (viewData.canEdit) {
                hotkeys.add({
                    combo: 'alt+shift+i',
                    description: 'shortcuts.add',
                    callback: onAddClick
                });
            }
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'dateLogicRules',
                autoBind: true,
                pageable: false,
                sortable: false,
                actions: viewData.canEdit ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: true
                } : null,
                topicItemNumberKey: {
                    key: vm.topic.key,
                    isSubSection: true
                },
                read: function () {
                    return service.getDateLogicRules(criteriaId, eventId);
                },
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, ' +
                    '\'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: prefix + 'appliesTo',
                    template: '{{ vm.formatAppliesTo(dataItem) }}'
                }, {
                    title: prefix + 'operator',
                    field: 'operator.value'
                }, {
                    title: prefix + 'compareEvent',
                    template: '{{ vm.formatPicklistColumn(dataItem.compareEvent) }}'
                }, {
                    title: prefix + 'compareType',
                    template: '{{ vm.formatCompareType(dataItem) }}'
                }, {
                    title: prefix + 'cycle',
                    template: '{{ vm.formatRelativeCycle(dataItem) }}'
                }, {
                    title: prefix + 'useCaseRelationship',
                    template: '{{ vm.formatPicklistColumn(dataItem.caseRelationship) }}'
                }, {
                    title: prefix + 'blockOrWarnUser',
                    template: '{{ vm.formatIfRuleFails(dataItem) }}'
                }]
            });
        }

        function onEditClick(dataItem) {
            openDatesLogicMaintenance('edit', dataItem);
        }

        function onAddClick() {
            openDatesLogicMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function addItem(newData) {
            var insertIndex = vm.gridOptions.dataSource.data().length + 1;
            vm.gridOptions.dataSource.insert(insertIndex, newData);
        }

        function formatAppliesTo(dataItem) {
            switch (dataItem.appliesTo) {
                case 'Event':
                    return $translate.instant(maintenancePrefix + 'eventDate');
                case 'Due':
                    return $translate.instant(maintenancePrefix + 'dueDate');
            }

            return '';
        }

        function formatCompareType(dataItem) {
            switch (dataItem.compareType) {
                case 'Event':
                    return $translate.instant(maintenancePrefix + 'eventDate');
                case 'Due':
                    return $translate.instant(maintenancePrefix + 'dueDate');
                case 'Either':
                    return $translate.instant(maintenancePrefix + 'eventDue');
            }

            return '';
        }

        function formatIfRuleFails(dataItem) {
            switch (dataItem.ifRuleFails) {
                case 'Block':
                    return $translate.instant(maintenancePrefix + 'blockUser');
                case 'Warn':
                    return $translate.instant(maintenancePrefix + 'warnUser');
            }

            return '';
        }

        function formatRelativeCycle(dataItem) {
            return service.translateRelativeCycle(dataItem.relativeCycle);
        }

        function openDatesLogicMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'DateLogicMaintenance',
                mode: mode,
                dataItem: dataItem || {},
                allItems: vm.gridOptions.dataSource.data(),
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                eventDescription: viewData.overview.data.description,
                isAddAnother: false,
                addItem: addItem
            });
        }

        function getFormData() {
            var delta = workflowsEventControlService.mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);

            return {
                datesLogicDelta: delta
            };
        }

        function isDirty() {
            return kendoGridService.isGridDirty(vm.gridOptions);
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                appliesTo: data.appliesTo,
                operator: data.operator.key,
                compareEventId: data.compareEvent && data.compareEvent.key,
                compareType: data.compareType,
                caseRelationshipId: data.caseRelationship && data.caseRelationship.key,
                relativeCycle: data.relativeCycle,
                eventMustExist: data.eventMustExist,
                ifRuleFails: data.ifRuleFails,
                failureMessage: data.failureMessage
            };
        }
    }
});