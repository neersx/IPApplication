angular.module('inprotech.configuration.general.nametypes')
    .controller('NameTypesController', NameTypesController);


function NameTypesController($scope, kendoGridBuilder, nameTypesService, menuSelection, modalService, notificationService, states, viewData, hotkeys, BulkMenuOperations, $translate, $timeout) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {

        vm.context = 'nametypes';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.add = add;
        vm.edit = edit;
        vm.duplicate = duplicate;
        vm.openNameTypeMaintenance = openNameTypeMaintenance;
        vm.deleteSelectedNameTypes = deleteSelectedNameTypes;
        vm.launchNameTypesPriorityOrder = launchNameTypesPriorityOrder;
        vm.resetSearchCriteria = resetSearchCriteria;
        vm.actions = buildMenu();

        vm.gridOptions = buildGridOptions();

        resetSearchCriteria();
        $timeout(initShortcuts, 500);
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            scrollable: false,
            reorderable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
            autoBind: true,
            serverFiltering: false,
            onDataCreated: function () {
                nameTypesService.persistSavedNameTypes(vm.gridOptions.data());
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            read: doSearch,
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.actions" data-context="nametypes" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'Code',
                field: 'code',
                width: '130px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.code"></a>'
            }, {
                title: 'Description',
                field: 'description',
                width: '400px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>'
            }, {
                title: 'nameType.maintenance.nameTypeGroup',
                field: 'nameGroup',
                width: '600px',
                sortable: false,
                template: '<span ng-repeat="nameTypeGroup in dataItem.nameTypeGroups track by $index"><span ng-if="$index > 0">, </span><span ng-style="{\'font-weight\': vm.highlightFilteredNameGroup(nameTypeGroup)}">{{nameTypeGroup.description}}</span></span>'
            },
            {
                title: 'nameType.priorityOrder',
                field: 'priorityOrder',
                sortable: true
            }]
        });
    }

    function doSearch() {
        return nameTypesService.search(vm.searchCriteria);
    }

    vm.clearAll = function () {
        return bulkMenuOperations.clearAll(vm.gridOptions.data());
    };

    vm.selectAll = function (val) {
        return bulkMenuOperations.selectAll(vm.gridOptions.data(), val);
    };

    vm.selectionChange = function (dataItem) {
        if (dataItem && dataItem.inUse && dataItem.selected) {
            dataItem.inUse = false;
        }
        return bulkMenuOperations.selectionChange(vm.gridOptions.data());
    };

    vm.highlightFilteredNameGroup = function (nameTypeGroup) {
        if (vm.searchCriteria.nameTypeGroup !== null && nameTypeGroup !== undefined) {
            if (_.any(vm.searchCriteria.nameTypeGroup, function (item) {
                return (item.key === nameTypeGroup.id);
            }))
                return 'bold';
        }
    }

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function buildMenu() {
        return [{
            id: 'edit',
            enabled: anySelected,
            click: edit,
            maxSelection: 1
        }, {
            id: 'duplicate',
            enabled: anySelected,
            click: duplicate,
            maxSelection: 1
        }, {
            id: 'delete',
            enabled: anySelected,
            click: confirmAndDeleteSelectedNameTypes
        }];
    }

    function deleteSelectedNameTypes() {
        nameTypesService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
            function (response) {
                if (response.data.hasError) {
                    var allInUse = bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length === response.data.inUseIds.length;
                    var message = allInUse ? $translate.instant('modal.alert.alreadyInUse') :
                        $translate.instant('modal.alert.partialComplete') + '<br/>' + $translate.instant('modal.alert.alreadyInUse');
                    var title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                    vm.gridOptions.search().then(function () {
                        notificationService.alert({
                            title: title,
                            message: message
                        });
                        nameTypesService.markInUseNameTypes(vm.gridOptions.data(), response.data.inUseIds);
                        bulkMenuOperations.selectionChange(vm.gridOptions.data());
                    });
                } else {
                    notificationService.success(response.data.message);
                    vm.gridOptions.search();
                }
            });
    }

    function confirmAndDeleteSelectedNameTypes() {

        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;

        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelectedNameTypes();
        });
    }

    function openNameTypeMaintenance(entity, state) {
        entity.state = state;

        var dialog = modalService.openModal({
            id: 'NameTypeMaintenance',
            entity: entity,
            controllerAs: 'vm',
            searchCallbackFn: vm.gridOptions.search
        });
        dialog.then(function () {
            notificationService.success();
            vm.gridOptions.search();
        });
    }

    function add() {
        var entity = {
            minAllowedForCase: '0',
            displayNameCode: 'none',
            ethicalWallOption: 'notApplicable'
        };
        openNameTypeMaintenance(entity, states.adding);
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }

        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function edit(id) {
        var nameTypeId = getSelectedEntityId(id);
        nameTypesService.get(nameTypeId)
            .then(function (entity) {
                openNameTypeMaintenance(entity, states.updating);
            });
    }

    function duplicate() {
        var nameTypeId = getSelectedEntityId();
        nameTypesService.get(nameTypeId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            openNameTypeMaintenance(entityToBeAdded, states.duplicating);
        });
    }

    function resetSearchCriteria() {
        vm.searchCriteria = {
            text: '',
            nameTypeGroup: null
        };
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                if (modalService.canOpen()) {
                    vm.add();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                if (modalService.canOpen()) {
                    confirmAndDeleteSelectedNameTypes();
                }
            }
        });
    }

    function launchNameTypesPriorityOrder() {
        var dialog =
            modalService.openModal({
                launchSrc: 'search',
                id: 'NameTypesOrder',
                controllerAs: 'vm'
            });
        dialog.then(function () {
            vm.gridOptions.search();
        });
    }
}