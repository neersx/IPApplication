angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlEventsToUpdate', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/events-to-update.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, inlineEdit, workflowsEventControlService, hotkeys) {
        'use strict';

        var service = workflowsEventControlService;
        var createObj;
        var vm = this;
        var viewData;
        var prefix;
        var canEdit;
        var criteriaId;
        var eventId;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            prefix = 'workflows.eventcontrol.eventsToUpdate.';
            canEdit = viewData.canEdit;
            criteriaId = viewData.criteriaId;
            eventId = viewData.eventId;
            vm.topic.initializeShortcuts = initShortcuts;
            createObj = inlineEdit.defineModel([{
                name: 'eventToUpdate',
                equals: function (objA, objB) {
                    return objA.key === objB.key;
                }
            },
                'relativeCycle',
                'adjustDate'
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
                displayDateAdjustment: displayDateAdjustment,
                eventPicklistScope: service.initEventPicklistScope({
                    criteriaId: criteriaId,
                    filterByCriteria: true
                }),
                onAddClick: onAddClick,
                onEventChanged: onEventChanged,
                dateAdjustmentOptions: viewData.syncedEventSettings.dateAdjustmentOptions
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
                id: 'eventsToUpdateGrid',
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
                    return service.getEventsToUpdate(criteriaId, eventId).then(function (data) {
                        return _.map(data, createObj);
                    });
                },
                autoGenerateRowTemplate: canEdit,
                rowAttributes: canEdit ? 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted,' +
                    ' \'input-inherited\': dataItem.isInherited && !dataItem.isDirty()}"' :
                    'ng-class="{\'input-inherited\': dataItem.isInherited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isDirty()">'
                }, {
                    title: prefix + 'eventToUpdate',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.formatPicklistColumn(dataItem.eventToUpdate)"></span>' +
                        '<ip-typeahead ip-field-error="{{dataItem.error(\'duplicate\') ? \'Duplicate\' : \'\'}}" ng-if="!dataItem.deleted" picklist-can-maintain="true" focus-on-add ip-required label="" name="event" ng-model="dataItem.eventToUpdate" ng-change="vm.onEventChanged(dataItem)" config="eventsFilteredByCriteria" external-scope="vm.eventPicklistScope" extend-query="vm.eventPicklistScope.extendQuery"></ip-typeahead>' : '<span ng-bind="vm.formatPicklistColumn(dataItem.eventToUpdate)"></span>'
                }, {
                    title: 'workflows.common.eventNo',
                    hidden: !canEdit,
                    width: '10%',
                    template: '<span ng-bind="vm.formatEventNo(dataItem.eventToUpdate)"></span>'
                }, {
                    title: prefix + 'cycle',
                    field: 'relativeCycle',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" ip-required name="relativeCycle" ng-model="dataItem.relativeCycle"  options="option.key as option.value | translate for option in vm.relativeCycles| filter:{ showAll: \'true\'}"></ip-dropdown>' : '<span ng-bind="vm.displayRelativeCycle(dataItem.relativeCycle)"></span>'
                }, {
                    title: prefix + 'adjustDate',
                    field: 'adjustDate',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.displayDateAdjustment(dataItem)"></span>' +
                        '<ip-dropdown ng-if="!dataItem.deleted" label="" name="adjustDate" ng-model="dataItem.adjustDate" options="option.key as option.value | translate for option in vm.dateAdjustmentOptions"></ip-dropdown>' : '<span ng-bind="vm.displayDateAdjustment(dataItem)"></span>'
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
            var item = service.findLastDuplicate(all, ['eventToUpdate']);
            if (item && item.eventToUpdate) {
                item.error('duplicate', true);
            }

            return vm.form.$validate() && !item;
        }

        function getFormData() {
            var all = vm.gridOptions.dataSource.data();
            var delta = inlineEdit.createDelta(all, convertToSaveModel);
            return {
                eventsToUpdateDelta: delta
            };
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                eventToUpdateId: data.eventToUpdate.key,
                relativeCycle: data.relativeCycle,
                adjustDate: data.adjustDate
            };
        }

        function onEventChanged(dataItem) {
            if (isDuplicate(dataItem)) {
                dataItem.error('duplicate', true);
            } else {
                dataItem.error('duplicate', false);
            }
            updateRelativeCycle(dataItem);
        }

        function isDuplicate(dataItem) {
            var all = vm.gridOptions.dataSource.data();
            return service.isDuplicated(all, dataItem, ['eventToUpdate']);
        }

        function updateRelativeCycle(dataItem) {
            if (dataItem.eventToUpdate) {
                dataItem.relativeCycle = service.getDefaultRelativeCycle(dataItem.eventToUpdate);
            }
        }

        function displayDateAdjustment(dataItem) {
            if (!dataItem || !dataItem.adjustDate) {
                return '';
            }

            var r = _.find(vm.dateAdjustmentOptions, function (a) {
                return a.key === dataItem.adjustDate;
            });

            return r ? r.value : '';
        }
    }
});