angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlUserAccess', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/userAccess.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEntryControlService, picklistService, kendoGridService, hotkeys) {
        'use strict';

        var criteriaId;
        var entryId;
        var viewData;
        var service;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            service = workflowsEntryControlService;
            vm.canEdit = viewData.canEdit;
            vm.onAddClick = selectEventToAdd;

            vm.topic.getFormData = getTopicFormData;
            vm.topic.isDirty = isDirty;
            vm.topic.hasError = function () {
                return false;
            };
            vm.topic.initializeShortcuts = initShortcuts;

            criteriaId = viewData.criteriaId;
            entryId = viewData.entryId;

            vm.gridOptions = buildGridOptions();

            vm.topic.initialised = true;
        }

        function initShortcuts() {
            if (viewData.canEdit) {
                hotkeys.add({
                    combo: 'alt+shift+i',
                    description: 'shortcuts.add',
                    callback: selectEventToAdd
                });
            }
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'userAccess',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                titlePrefix: 'workflows.entrycontrol.userAccess',
                autoGenerateRowTemplate: true,
                actions: vm.canEdit ? {
                    delete: true
                } : null,
                read: function () {
                    return service.getUserAccess(criteriaId, entryId);
                },
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: '.role',
                    field: 'value'
                }],
                detailTemplate: '<ip-workflows-entry-control-user-access-users data-role-id=\'{{::dataItem.key}}\'></ip-workflows-entry-control-user-access-users>',
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.deleted, deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited && !dataItem.isEdited}"'
            });
        }

        function selectEventToAdd() {
            picklistService.openModal($scope, {
                displayName: 'picklist.role.Type',
                multipick: true,
                selectedItems: kendoGridService.activeData(vm.gridOptions),
                label: 'picklist.role.Name',
                keyField: 'key',
                textField: 'value',
                apiUrl: 'api/picklists/roles',
                picklistDisplayName: 'picklist.role.Name',
                columns: [{
                    title: "picklist.role.description",
                    field: "value"
                }]
            })
                .then(function (selectedRoles) {
                    kendoGridService.sync(vm.gridOptions, selectedRoles);
                });
        }

        function getTopicFormData() {
            var added = getSaveModel(function (data) {
                return data.isAdded && !data.deleted;
            });
            var deleted = getSaveModel(function (data) {
                return data.deleted;
            });

            return {
                userAccessDelta: {
                    added: added,
                    deleted: deleted
                }
            };
        }

        function getSaveModel(filter) {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(filter)
                .map(function (data) {
                    return data.key;
                })
                .value();
        }

        function isDirty() {
            var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
            var dirtyGrid = data && _.any(data, function (item) {
                return item.isAdded || item.deleted;
            });

            return dirtyGrid;
        }        
    }
});