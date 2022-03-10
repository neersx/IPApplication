angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlDateComparison', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/date-comparison.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, $translate, hotkeys, modalService, workflowsEventControlService, kendoGridService, dateService) {
        'use strict';

        var service;
        var viewData;
        var prefix;
        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService;
            viewData = vm.topic.params.viewData;
            prefix = 'workflows.eventcontrol.dateComparison.';
            vm.topic.initializeShortcuts = initShortcuts;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? { datesLogicComparisonType: viewData.parent.datesLogicComparisonType } : {};

            _.extend(vm, {
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                canEdit: viewData.canEdit,
                gridOptions: buildGridOptions(),
                onAddClick: onAddClick,
                onEditClick: onEditClick,
                formatPicklistColumn: service.formatPicklistColumn,
                formatCompareType: formatCompareType,
                formatCompareWith: formatCompareWith,
                showComparisonOperator: showComparisonOperator,
                showRelativeCycle: showRelativeCycle,
                formData: {
                    datesLogicComparisonType: viewData.datesLogicComparisonType
                }
            });

            vm.comparisonOptionsDisabled = comparisonOptionsDisabled;

            vm.topic.isDirty = isDirty;
    
            vm.topic.getFormData = getFormData;
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

        function addItem(newData) {
            service.translateOperator(newData.comparisonOperator);
            var insertIndex = vm.gridOptions.dataSource.data().length + 1;
            vm.gridOptions.dataSource.insert(insertIndex, newData);
        }

        function onAddClick() {
            openDateComparisonMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openDateComparisonMaintenance('edit', dataItem);
        }

        function openDateComparisonMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'DateComparisonMaintenance',
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

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'dateComparisonResults',
                autoBind: true,
                pageable: false,
                sortable: false,
                actions: viewData.canEdit ? {
                    delete: true,
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    }
                } : null,
                topicItemNumberKey: {
                    key: vm.topic.key,
                    isSubSection: true
                },
                read: function () {
                    return service.getDateComparisons(vm.criteriaId, vm.eventId)
                        .then(function (data) {
                            _.each(data, function (ele) {
                                service.translateOperator(ele.comparisonOperator);
                            });
                            return data;
                        });
                },
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: prefix + 'eventA',
                    template: '{{ vm.formatPicklistColumn(dataItem.eventA) }}'
                }, {
                    title: prefix + 'useDate',
                    template: '{{ vm.formatCompareType(dataItem.eventADate) }}'
                }, {
                    title: prefix + 'cycle',
                    template: '{{ vm.showRelativeCycle(dataItem.eventARelativeCycle) }}'
                }, {
                    title: prefix + 'comparison',
                    template: '{{ vm.showComparisonOperator(dataItem) }}'
                }, {
                    title: prefix + 'eventB',
                    template: '{{ vm.formatCompareWith(dataItem) }}'
                }, {
                    title: prefix + 'useDate',
                    template: '{{ vm.formatCompareType(dataItem.eventBDate) }}'
                }, {
                    title: prefix + 'cycle',
                    template: '{{ vm.showRelativeCycle(dataItem.eventBRelativeCycle) }}'
                }],
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"'
            });
        }

        function showComparisonOperator(dataItem) {
            return !dataItem.comparisonOperator ? '' : dataItem.comparisonOperator.value;
        }

        function getFormData() {
            var delta = service.mapGridDelta(getGridData(), convertToSaveModel);

            return {
                datesLogicCompare: vm.formData.datesLogicComparisonType,
                dateComparisonDelta: delta
            };
        }

        function isDirty() {
            return vm.form.$dirty || kendoGridService.isGridDirty(vm.gridOptions);
        }

        function comparisonOptionsDisabled() {
            var data = getGridData();
            return !vm.canEdit || !data || data.length === 0
        }

        function getGridData() {
            return vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
        }

        function formatCompareWith(dataItem) {
            if (dataItem.comparisonOperator)
                if (dataItem.comparisonOperator.key === 'EX' || dataItem.comparisonOperator.key === 'NE') return '';

            if (dataItem.eventB) return service.formatPicklistColumn(dataItem.eventB);
            if (dataItem.compareDate) return dateService.format(dataItem.compareDate);
            return $translate.instant('workflows.eventcontrol.dateComparison.maintenance.systemDate');
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                eventAId: data.eventA.key,
                eventADate: data.eventADate,
                eventARelativeCycle: data.eventARelativeCycle,
                comparisonOperator: data.comparisonOperator.key,
                eventBId: data.eventB && data.eventB.key,
                eventBDate: data.eventBDate,
                eventBRelativeCycle: data.eventBRelativeCycle,
                compareRelationshipId: data.compareRelationship && data.compareRelationship.key,
                compareDate: data.compareDate,
                compareSystemDate: data.compareSystemDate
            };
        }

        function formatCompareType(compareType) {
            switch (compareType) {
                case 'Event':
                    return $translate.instant('workflows.common.eventDate');
                case 'Due':
                    return $translate.instant('workflows.common.dueDate');
                case 'EventOrDue':
                    return $translate.instant('workflows.eventcontrol.dateComparison.maintenance.eventOrDue');
            }
            return '';
        }

        function showRelativeCycle(relativeCycle) {
            if (relativeCycle == null) {
                return '';
            }

            return $translate.instant(service.translateRelativeCycle(relativeCycle));
        }
    }
});