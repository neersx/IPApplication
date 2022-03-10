angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlEventsToClear', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/events-to-clear.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, inlineEdit, workflowsEventControlService, hotkeys) {
        'use strict';

        var service;
        var viewData;
        var prefix;
        var canEdit;
        var criteriaId;
        var eventId;
        var createObj;

        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService;
            viewData = vm.topic.params.viewData;
            prefix = 'workflows.eventcontrol.eventsToClear.';
            canEdit = viewData.canEdit;
            criteriaId = viewData.criteriaId;
            eventId = viewData.eventId;
            vm.topic.initializeShortcuts = initShortcuts;
            createObj = inlineEdit.defineModel([{
                name: 'eventToClear',
                equals: function (objA, objB) {
                    return objA.key === objB.key;
                }
            },
                'relativeCycle',
                'clearEventOnEventChange',
                'clearDueDateOnEventChange',
                'clearEventOnDueDateChange',
                'clearDueDateOnDueDateChange'
            ]);

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate
            });

            _.extend(vm, {
                criteriaId: criteriaId,
                eventId: eventId,
                canEdit: canEdit,
                formatPicklistColumn: service.formatPicklistColumn,
                formatEventNo: service.formatEventNo,
                gridOptions: buildGridOptions(),
                relativeCycles: service.relativeCycles,
                displayRelativeCycle: service.translateRelativeCycle,
                eventPicklistScope: service.initEventPicklistScope({
                    criteriaId: criteriaId,
                    filterByCriteria: true
                }),
                onAddClick: onAddClick,
                onEventChanged: onEventChanged,
                onCheckboxChange: validateClearingCheckbox
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

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'eventsToClearResults',
                autoBind: true,
                pageable: false,
                sortable: false,
                actions: canEdit ? {
                    delete: true
                } : null,
                topicItemNumberKey: {
                    key: vm.topic.key,
                    isSubSection: true
                },
                read: function () {
                    return service.getEventsToClear(criteriaId, eventId).then(function (data) {
                        return _.map(data, createObj);
                    });
                },
                autoGenerateRowTemplate: canEdit,
                rowAttributes: canEdit ? 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited && !dataItem.isDirty()}"' +
                    ' uib-tooltip="{{\'workflows.eventcontrol.eventsToClear.tickCheckbox\' | translate}}" tooltip-enable="dataItem.error(\'checkbox\')" tooltip-class="tooltip-error" data-tooltip-placement="left"' :
                    'ng-class="{\'input-inherited\': dataItem.isInherited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isDirty()"></ip-inheritance-icon>'
                }, {
                    title: prefix + 'eventToClear',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.formatPicklistColumn(dataItem.eventToClear)"></span>' +
                        '<ip-typeahead ip-field-error="{{dataItem.error(\'duplicate\') ? \'Duplicate\' : \'\'}}" ng-if="!dataItem.deleted" picklist-can-maintain="true" focus-on-add ip-required label="" name="event" ng-model="dataItem.eventToClear" ng-change="vm.onEventChanged(dataItem)" config="eventsFilteredByCriteria" external-scope="vm.eventPicklistScope" extend-query="vm.eventPicklistScope.extendQuery"></ip-typeahead>' : '<span ng-bind="vm.formatPicklistColumn(dataItem.eventToClear)">{{dataItem.eventToClear}}</span>'
                }, {
                    title: 'workflows.common.eventNo',
                    hidden: !canEdit,
                    width: '10%',
                    template: '<span ng-bind="vm.formatEventNo(dataItem.eventToClear)"></span>'
                }, {
                    title: prefix + 'cycle',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" ip-required name="relativeCycle" ng-model="dataItem.relativeCycle"  options="option.key as option.value | translate for option in vm.relativeCycles"></ip-dropdown>' : '<span ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>'
                }, {
                    title: prefix + 'whenEventOccurs',
                    columns: [{
                        title: prefix + 'clearEventDate',
                        template: '<ip-checkbox ng-model="dataItem.clearEventOnEventChange" ng-disabled="!vm.canEdit || dataItem.deleted" ng-change="vm.onCheckboxChange(dataItem)">'
                    }, {
                        title: prefix + 'clearDueDate',
                        template: '<ip-checkbox ng-model="dataItem.clearDueDateOnEventChange" ng-disabled="!vm.canEdit || dataItem.deleted" ng-change="vm.onCheckboxChange(dataItem)">'
                    }]
                }, {
                    title: prefix + 'whenDueDateCalculates',
                    columns: [{
                        title: prefix + 'clearEventDate',
                        template: '<ip-checkbox ng-model="dataItem.clearEventOnDueDateChange" ng-disabled="!vm.canEdit || dataItem.deleted" ng-change="vm.onCheckboxChange(dataItem)">'
                    }, {
                        title: prefix + 'clearDueDate',
                        template: '<ip-checkbox ng-model="dataItem.clearDueDateOnDueDateChange" ng-disabled="!vm.canEdit || dataItem.deleted" ng-change="vm.onCheckboxChange(dataItem)">'
                    }]
                }]
            });
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            vm.gridOptions.insertRow(insertIndex, createObj());
        }

        function hasError() {
            return vm.form.$invalid || inlineEdit.hasError(vm.gridOptions.dataSource.data());
        }

        function isDirty() {
            return inlineEdit.canSave(vm.gridOptions.dataSource.data());
        }

        function validate() {
            var all = vm.gridOptions.dataSource.data();
            var isClearingCheckboxValid = true;

            _.each(all, function (a) {
                if (!validateClearingCheckbox(a)) {
                    isClearingCheckboxValid = false;
                }
            });

            var item = service.findLastDuplicate(all, ['eventToClear']);
            if (item && item.eventToClear) {
                item.error('duplicate', true);
            }

            return vm.form.$validate() && !item && isClearingCheckboxValid;
        }

        function getFormData() {
            var delta = inlineEdit.createDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                eventsToClearDelta: delta
            };
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                eventToClearId: data.eventToClear.key,
                relativeCycle: data.relativeCycle,
                clearEventOnEventChange: data.clearEventOnEventChange,
                clearDueDateOnEventChange: data.clearDueDateOnEventChange,
                clearEventOnDueDateChange: data.clearEventOnDueDateChange,
                clearDueDateOnDueDateChange: data.clearDueDateOnDueDateChange
            };
        }

        function onEventChanged(dataItem) {
            if (isDuplicate(dataItem)) {
                dataItem.error('duplicate', true);
            } else {
                dataItem.error('duplicate', false);
            }
            updateRelativeCycle(dataItem);
            defaultEventDateCheckbox(dataItem);
        }

        function defaultEventDateCheckbox(dataItem) {
            if (
                dataItem.eventToClear &&
                !dataItem.clearDueDateOnDueDateChange &&
                !dataItem.clearDueDateOnEventChange &&
                !dataItem.clearEventOnDueDateChange &&
                !dataItem.clearEventOnEventChange
            ) {
                dataItem.clearEventOnEventChange = true;
            }
            vm.onCheckboxChange(dataItem);
        }

        function validateClearingCheckbox(dataItem) {
            if (!dataItem) {
                return true;
            }

            var isValid = Boolean(dataItem.clearEventOnEventChange || dataItem.clearDueDateOnEventChange || dataItem.clearEventOnDueDateChange || dataItem.clearDueDateOnDueDateChange);

            dataItem.error('checkbox', !isValid);

            return isValid;
        }

        function isDuplicate(dataItem) {
            var all = vm.gridOptions.dataSource.data();
            return service.isDuplicated(all, dataItem, ['eventToClear']);
        }

        function updateRelativeCycle(dataItem) {
            if (dataItem.eventToClear) {
                if (dataItem.eventToClear.maxCycles == 1) {
                    dataItem.relativeCycle = 3;
                } else {
                    dataItem.relativeCycle = 0;
                }
            }
        }
    }
});