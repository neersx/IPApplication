angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlSatisfyingEvents', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/satisfying-events.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEventControlService, kendoGridService, hotkeys) {
        'use strict';

        var service = workflowsEventControlService;
        var vm = this;
        var viewData;
        var prefix;
        var canEdit;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            prefix = 'workflows.eventcontrol.satisfyingEvents.';
            canEdit = viewData.canEdit;
            vm.topic.initializeShortcuts = initShortcuts;

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate
            });

            _.extend(vm, {
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                canEdit: viewData.canEdit,
                formatPicklistColumn: service.formatPicklistColumn,
                formatEventNo: service.formatEventNo,
                gridOptions: buildGridOptions(),
                relativeCycles: service.relativeCycles,
                displayRelativeCycle: service.translateRelativeCycle,
                eventPicklistScope: service.initEventPicklistScope({
                    criteriaId: viewData.criteriaId,
                    filterByCriteria: true
                }),
                checkDuplicate: checkDuplicate,
                onAddClick: onAddClick,
                onEventChanged: onEventChanged,
                onCycleChanged: onCycleChanged
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
                id: 'satisfyingEventsResults',
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
                    return service.getSatisfyingEvents(vm.criteriaId, vm.eventId);
                },
                autoGenerateRowTemplate: canEdit,
                rowAttributes: canEdit ? 'ng-form="rowForm" ng-class="{error: rowForm.$invalid, edited: dataItem.isEdited || dataItem.added ||dataItem.deleted, deleted: dataItem.deleted' +
                    ',\'input-inherited\': dataItem.isInherited && !dataItem.isEdited}"' : 'ng-class="{\'input-inherited\': dataItem.isInherited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: 'workflows.common.event',
                    width: canEdit ? '40%' : '50%',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.formatPicklistColumn(dataItem.satisfyingEvent)"></span>' +
                        '{{vm.checkDuplicate(dataItem.isDuplicatedRecord, rowForm)}}' +
                        '<ip-typeahead data-picklist-can-maintain="true" ng-if="!dataItem.deleted" focus-on-add ip-required label="" name="event" ng-model="dataItem.satisfyingEvent" ng-change="vm.onEventChanged(dataItem, rowForm)" data-config="eventsFilteredByCriteria" data-external-scope="vm.eventPicklistScope" data-extend-query="vm.eventPicklistScope.extendQuery"></ip-typeahead>' :
                        '<span ng-bind="vm.formatPicklistColumn(dataItem.satisfyingEvent)"></span>'
                }, {
                    title: 'workflows.common.eventNo',
                    hidden: !canEdit,
                    width: '10%',
                    template: '<span ng-bind="vm.formatEventNo(dataItem.satisfyingEvent)"></span>'
                }, {
                    title: prefix + 'cycle',
                    width: '50%',
                    field: 'relativeCycle',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" ip-required name="relativeCycle" ng-model="dataItem.relativeCycle" ng-change="vm.onCycleChanged(dataItem, rowForm)" options="option.key as option.value | translate for option in vm.relativeCycles | filter:{ showAll: \'true\'}"></ip-dropdown>' : '<span ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>'
                }]
            });
        }

        function checkDuplicate(isDuplicatedRecord, rowForm) {
            if (isDuplicatedRecord) {
                rowForm.event.$setValidity('duplicate', false);
            }
        }

        function onAddClick() {
            if (hasError())
                return;
            var insertIndex = vm.gridOptions.dataSource.total();
            vm.gridOptions.insertRow(insertIndex, {
                added: true
            });
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty || kendoGridService.isGridDirty(vm.gridOptions);
        }

        function validate() {
            return vm.form.$validate();
        }

        function onEventChanged(dataItem, rowForm) {
            dataItem.isEdited = true;
            rowForm.event.$setValidity('duplicate', true);
            rowForm.relativeCycle.$setValidity('duplicate', true);
            dataItem.isDuplicatedRecord = false;
            if (isDuplicate(dataItem)) {
                if (dataItem.satisfyingEvent.maxCycles === 1) {
                    rowForm.event.$setValidity('duplicate', false);
                }
            }
            updateRelativeCycle(dataItem, rowForm);
        }

        function onCycleChanged(dataItem, rowForm) {
            dataItem.isEdited = true;
            if (dataItem.satisfyingEvent.maxCycles === 1) {
                return;
            }
            rowForm.relativeCycle.$setValidity('duplicate', true);
            dataItem.isDuplicatedRecord = false;
            if (isDuplicate(dataItem)) {
                var duplicates = _.countBy(vm.gridOptions.dataSource.data(), function (i) {
                    return (i.relativeCycle === dataItem.relativeCycle) && (i.satisfyingEvent.key === dataItem.satisfyingEvent.key);
                });
                if (duplicates.true > 1) {
                    rowForm.relativeCycle.$setValidity('duplicate', false);
                }
            }
        }

        function isDuplicate(dataItem) {
            var all = vm.gridOptions.dataSource.data();
            return service.isDuplicated(_.without(all, dataItem), dataItem, ['satisfyingEvent']);
        }

        function updateRelativeCycle(dataItem, rowForm) {
            if (dataItem.satisfyingEvent) {
                if (dataItem.satisfyingEvent.maxCycles == 1) {
                    dataItem.relativeCycle = 3;
                } else {
                    dataItem.relativeCycle = 0;
                }
                onCycleChanged(dataItem, rowForm);
            }
        }

        function getFormData() {
            var delta = service.mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                satisfyingEventsDelta: delta
            };
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                satisfyingEventId: data.satisfyingEvent.key,
                relativeCycle: data.relativeCycle
            };
        }
    }
});