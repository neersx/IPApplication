angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlDuedatecalc', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/due-date-calc.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, $translate, kendoGridBuilder, hotkeys, modalService, workflowsDueDateCalcService, workflowsEventControlService, kendoGridService) {
        'use strict';

        var service;
        var eventControlService;
        var viewData;
        var prefix;
        var prefixOperatorMap;
        var prefixFromToEventMap;
        var operatorMap;
        var fromToEventMap;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowsDueDateCalcService;
            eventControlService = workflowsEventControlService;
            viewData = vm.topic.params.viewData;
            prefix = 'workflows.eventcontrol.dueDateCalc.';
            prefixOperatorMap = prefix + 'operatorMap.';
            prefixFromToEventMap = prefix + 'fromToEventMap.';
            operatorMap = {
                'S': prefixOperatorMap + 'subtract',
                'A': prefixOperatorMap + 'add'
            };
            fromToEventMap = {
                '1': prefixFromToEventMap + 'Event Date',
                '2': prefixFromToEventMap + 'Due Date',
                '3': prefixFromToEventMap + 'EventDue'
            };

            vm.topic.validate = validate;
            vm.topic.hasError = hasError;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;
            vm.topic.initializeShortcuts = initShortcuts;
            vm.isInherited = isInherited;

            _.extend(vm, {
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                canEdit: viewData.canEdit,
                settings: service.initSettingsViewModel(viewData.dueDateCalcSettings),
                parentData: (viewData.isInherited === true && viewData.parent) ? service.initSettingsViewModel(viewData.parent.dueDateCalcSettings) : {},
                extendDueDateByUnitOptions: [{
                    name: eventControlService.translatePeriodType('D'),
                    value: 'D'
                }, {
                    name: eventControlService.translatePeriodType('M'),
                    value: 'M'
                }, {
                    name: eventControlService.translatePeriodType('W'),
                    value: 'W'
                }, {
                    name: eventControlService.translatePeriodType('Y'),
                    value: 'Y'
                }],
                gridOptions: buildGridOptions(),
                updateSaveDueDate: updateSaveDueDate,
                updateExtendDueDate: updateExtendDueDate,
                onAddClick: onAddClick,
                onEditClick: onEditClick,
                showOperator: showOperator,
                showRelativeCycle: showRelativeCycle,
                showAdjustBy: showAdjustBy,
                showPeriod: showPeriod,
                showFromTo: showFromTo,
                formatPicklistColumn: eventControlService.formatPicklistColumn,
                showJurisdiction: showJurisdiction,
                onDeleteClick: checkIfDependOnStandingInstructions
            });
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

        function isInherited() {
            return (
                vm.settings.dateToUse === vm.parentData.dateToUse &&
                vm.settings.isSaveDueDate === vm.parentData.isSaveDueDate &&
                vm.settings.extendDueDate === vm.parentData.extendDueDate &&
                angular.equals(vm.settings.extendDueDateOptions, vm.parentData.extendDueDateOptions) &&
                vm.settings.recalcEventDate === vm.parentData.recalcEventDate &&
                vm.settings.doNotCalculateDueDate === vm.parentData.doNotCalculateDueDate
            );
        }

        function buildGridOptions() {
            var columns = [{
                fixed: true,
                width: '35px',
                template: '<ip-inheritance-icon ng-if="dataItem.inherited&&!dataItem.isDirty()"></ip-inheritance-icon>'
            }, {
                title: prefix + 'cycle',
                field: 'cycle'
            }, {
                title: prefix + 'jurisdiction',
                template: '{{ vm.showJurisdiction(dataItem) }}'
            }, {
                title: prefix + 'operator',
                template: '{{ vm.showOperator(dataItem) }}'
            }, {
                title: prefix + 'period',
                template: '{{ vm.showPeriod(dataItem)}}'
            }, {
                title: 'workflows.common.event',
                template: '{{ vm.formatPicklistColumn(dataItem.fromEvent)}}'
            }, {
                title: prefix + 'fromTo',
                template: '{{ vm.showFromTo(dataItem)}}'
            }, {
                title: prefix + 'cycle',
                template: '{{ vm.showRelativeCycle(dataItem) }}'
            }, {
                title: prefix + 'adjustBy',
                template: '{{ vm.showAdjustBy(dataItem) }}'
            }, {
                title: prefix + 'mustExist',
                field: 'mustExist',
                template: '<ip-checkbox ng-model="dataItem.mustExist" disabled></ip-checkbox>'
            }];

            if (!viewData.allowDueDateCalcJurisdiction) {
                columns.splice(2, 1);
            }

            return kendoGridBuilder.buildOptions($scope, {
                id: 'dueDateCalcResults',
                autoBind: true,
                pageable: false,
                sortable: false,
                topicItemNumberKey: {
                    key: vm.topic.key,
                    isSubSection: true
                },
                actions: viewData.canEdit ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: {
                        onClick: 'vm.onDeleteClick()'
                    }
                } : null,
                read: function () {
                    return service.getDueDateCalcs(vm.criteriaId, vm.eventId);
                },
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, \'input-inherited\': dataItem.inherited&&!dataItem.isDirty()}"',
                columns: columns,
                onDataBound: checkIfDependOnStandingInstructions
            });
        }

        function updateSaveDueDate() {
            if (vm.settings.isSaveDueDate) {
                vm.settings.extendDueDate = false;
            }
        }

        function updateExtendDueDate() {
            if (vm.settings.extendDueDate) {
                vm.settings.isSaveDueDate = false;
            }
        }

        function addItem(newData) {
            var insertIndex = vm.gridOptions.dataSource.data().length + 1;
            vm.gridOptions.dataSource.insert(insertIndex, newData);
        }

        function onAddClick() {
            openDueDateCalcMaintenance('add').then(function (newData) {
                addItem(newData);
                checkIfDependOnStandingInstructions();
            });
        }

        function onEditClick(dataItem) {
            openDueDateCalcMaintenance('edit', dataItem).then(function () {
                checkIfDependOnStandingInstructions();
            });
        }

        function openDueDateCalcMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'DueDateCalcMaintenance',
                /* hide this id to framework */
                mode: mode,
                /* pass all data */
                /* shouldn't specifiy template url*/
                /* it should be passed in the id for the actual modal content */
                // templateUrl: 'condor/configuration/rules/workflows/eventcontrol/due-date-calc-maintenance.html',
                dataItem: dataItem || {},
                allItems: vm.gridOptions.dataSource.data(),
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                eventDescription: viewData.overview.data.description,
                isCyclic: viewData.overview.data.maxCycles > 1,
                allowDueDateCalcJurisdiction: viewData.allowDueDateCalcJurisdiction,
                adjustByOptions: vm.settings.dateAdjustmentOptions,
                isAddAnother: false,
                addItem: addItem,
                standingInstructionCharacteristic: viewData.standingInstruction.requiredCharacteristic,
                maxCycles: viewData.overview.data.maxCycles
            });
        }

        function showOperator(data) {
            if (data.operator == null) {
                return '';
            }

            return $translate.instant(operatorMap[data.operator]);
        }

        function showRelativeCycle(data) {
            if (data.relativeCycle == null) {
                return '';
            }

            return $translate.instant(eventControlService.translateRelativeCycle(data.relativeCycle));
        }

        function showPeriod(data) {
            if (data.period == null) {
                return '';
            }

            var type = $translate.instant(eventControlService.translatePeriodType(data.period.type));
            return data.period.value == null ? type : data.period.value + ' ' + type;
        }

        function showFromTo(data) {
            if (data.fromTo == null) {
                return '';
            }

            return $translate.instant(fromToEventMap[data.fromTo]);
        }

        function showJurisdiction(data) {
            if (data.jurisdiction == null) {
                return '';
            }

            return data.jurisdiction.code;
        }

        function showAdjustBy(data) {
            if (data.adjustBy == null) {
                return '';
            }

            return _.find(vm.settings.dateAdjustmentOptions,
                function (element) {
                    return element.key === data.adjustBy;
                }).value;
        }

        function getFormData() {
            var delta = eventControlService.mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            var settings = service.getSettingsForSave(vm.settings);

            return _.extend({
                dueDateCalcDelta: delta
            }, settings);
        }

        function isDirty() {
            return vm.form.$dirty || kendoGridService.isGridDirty(vm.gridOptions);
        }

        function validate() {
            return vm.form.$validate();
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                fromEventId: data.fromEvent.key,
                fromTo: data.fromTo,
                mustExist: data.mustExist,
                operator: data.operator,
                period: data.period.value,
                periodType: data.period.type,
                adjustBy: data.adjustBy,
                nonWorkDay: data.nonWorkDay,
                relativeCycle: data.relativeCycle,
                cycle: data.cycle,
                jurisdictionId: data.jurisdiction && data.jurisdiction.key,
                documentId: data.document && data.document.key,
                reminderOption: data.reminderOption
            };
        }

        function checkIfDependOnStandingInstructions() {
            viewData.dueDateDependsOnStandingInstruction =
                vm.gridOptions.dataSource.data().some(function (item) {
                    return !item.deleted &&
                        (item.adjustBy == '~0' ||
                            item.period && (item.period.type == '1' || item.period.type == '2' || item.period.type == '3'));
                });

            viewData.dueDateCalcMaxCycles =
                Math.max.apply(Math, vm.gridOptions.dataSource.data().map(function (item) {
                    if (item.deleted) return 0;
                    return item.cycle || 0;
                }));
        }
    }
});