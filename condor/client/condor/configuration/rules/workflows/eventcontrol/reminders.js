angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlReminders', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/reminders.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, $translate, kendoGridBuilder, hotkeys, workflowsEventControlService, modalService, kendoGridService) {

        'use strict';

        var vm = this;
        var service;
        var viewData;
        var criteriaId;
        var eventId;
        var eventControlPrefix;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService;
            viewData = vm.topic.params.viewData;
            criteriaId = viewData.criteriaId;
            eventId = viewData.eventId;
            eventControlPrefix = 'workflows.eventcontrol.';
            vm.topic.initializeShortcuts = initShortcuts;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;

            _.extend(vm, {
                canEdit: viewData.canEdit,
                gridOptions: buildGridOptions(),
                onAddClick: onAddClick,
                onEditClick: onEditClick,
                showPeriodType: showPeriodType
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
                id: 'reminders',
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
                    return service.getReminders(criteriaId, eventId);
                },
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, ' +
                    ' \'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: eventControlPrefix + 'reminders.standardMessage',
                    field: 'standardMessage'
                }, {
                    title: eventControlPrefix + 'reminders.sendAsEmail',
                    fixed: true,
                    template: '<ip-checkbox ng-model="dataItem.sendEmail" disabled></ip-checkbox>'
                }, {
                    title: eventControlPrefix + 'startBefore',
                    field: 'startBefore',
                    template: '{{vm.showPeriodType(dataItem.startBefore)}}'
                }, {
                    title: eventControlPrefix + 'repeatEvery',
                    field: 'repeatEvery',
                    template: '{{vm.showPeriodType(dataItem.repeatEvery)}}'
                }, {
                    title: eventControlPrefix + 'stopAfter',
                    field: 'stop',
                    template: '{{vm.showPeriodType(dataItem.stopTime)}}'
                }]
            });
        }

        function showPeriodType(dataAttribute) {
            if (dataAttribute == null) {
                return '';
            }

            var type = $translate.instant(workflowsEventControlService.translatePeriodType(dataAttribute.type));
            return dataAttribute.value == null ? type : dataAttribute.value + ' ' + type;
        }

        function addItem(newData) {
            var insertIndex = vm.gridOptions.dataSource.data().length + 1;
            vm.gridOptions.dataSource.insert(insertIndex, newData);
        }

        function onAddClick() {
            openRemindersMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openRemindersMaintenance('edit', dataItem);
        }

        function openRemindersMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'RemindersMaintenance',
                /* hide this id to framework */
                mode: mode,
                /* pass all data */
                /* shouldn't specifiy template url*/
                /* it should be passed in the id for the actual modal content */
                // templateUrl: 'condor/configuration/rules/workflows/eventcontrol/reminders-maintenance.html',
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
                reminderRuleDelta: delta
            };
        }

        function isDirty() {
            return kendoGridService.isGridDirty(vm.gridOptions);
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                standardMessage: data.standardMessage,
                alternateMessage: data.alternateMessage,
                useOnAndAfterDueDate: data.useOnAndAfterDueDate,
                sendEmail: data.sendEmail,
                emailSubject: data.emailSubject,

                startBeforeTime: data.startBefore && data.startBefore.value,
                startBeforePeriod: data.startBefore && data.startBefore.type,
                repeatEveryTime: data.repeatEvery ? data.repeatEvery.value : 0,
                repeatEveryPeriod: data.repeatEvery ? data.repeatEvery.type : data.startBefore.type,

                stopTimePeriod: data.stopTime && data.stopTime.type,
                stopTime: data.stopTime && data.stopTime.value,
                sendToStaff: data.sendToStaff,
                sendToSignatory: data.sendToSignatory,
                sendToCriticalList: data.sendToCriticalList,
                name: data.name && data.name.key,
                relationship: data.relationship && data.relationship.key,
                nameTypes: _.pluck(data.nameTypes, 'code')
            };
        }
    }
});