angular.module('inprotech.configuration.general.texttypes')
    .controller('textTypesController', textTypesController);

function textTypesController($scope, kendoGridBuilder, textTypesService, menuSelection, modalService, notificationService, BulkMenuOperations, states, viewData, hotkeys, $translate) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'texttypes';
        vm.search = doSearch;
        vm.add = add;
        vm.duplicate = duplicate;
        vm.edit = edit;
        vm.changeTextTypeCode = changeTextTypeCode;
        vm.viewData = viewData;
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.deleteSelectedTextTypes = deleteSelectedTextTypes;
        vm.gridOptions = buildGridOptions();
        vm.textTypes = buildMenu();
        vm.searchCriteria = {
            text: ''
        };
        initShortcuts();
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            scrollable: false,
            reorderable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
            autoBind: true,
            serverFiltering: true,
            onDataCreated: function () {
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            read: doSearch,
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.textTypes" data-context="texttypes" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'textType.code',
                field: 'id',
                width: '130px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.id"></a>'
            }, {
                title: 'textType.description',
                field: 'description',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>'
            }, {
                title: 'textType.onlyCases',
                field: 'usedByCase',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.usedByCase" disabled="disabled"></input>'
            }, {
                title: 'textType.onlyName',
                field: 'usedByName',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.usedByName" disabled="disabled"></input>'
            }, {
                title: 'textType.staff',
                field: 'usedByEmployee',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.usedByEmployee" disabled="disabled"></input>'
            }, {
                title: 'textType.individual',
                field: 'usedByIndividual',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.usedByIndividual" disabled="disabled"></input>'
            }, {
                title: 'textType.organisation',
                field: 'usedByOrganisation',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.usedByOrganisation" disabled="disabled"></input>'
            }]
        });
    }


    function doSearch() {
        return textTypesService.search(vm.searchCriteria, vm.gridOptions.getQueryParams()).then(function (response) {
            vm.gridOptions.dataSource.data(response.data);
            textTypesService.searchResults = vm.gridOptions.data();
            bulkMenuOperations.selectionChange(vm.gridOptions.data());
            textTypesService.persistSavedTextTypes();
            return response.data;
        });
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

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function openTextTypeMaintenance(entity, state) {
        $scope.entity = entity;
        $scope.entity.state = state;
        var dialog = modalService.openModal({
            id: 'TextTypeMaintenance',
            entity: entity || {},
            dataItem: getEntityFromGrid(entity.id),
            allItems: vm.gridOptions.data(),
            controllerAs: 'vm',
            searchCallbackFn: vm.search
        });
        dialog.then(function () {
            vm.search();
        });
    }

    function getEntityFromGrid(id) {
        return _.find(vm.gridOptions.data(), function (item) {
            return item.id == id
        });
    }

    function add() {
        var entity = {};
        entity.usedByName = false;
        openTextTypeMaintenance(entity, states.adding);
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function duplicate() {
        var textTypeId = getSelectedEntityId();
        textTypesService.get(textTypeId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            openTextTypeMaintenance(entityToBeAdded, states.duplicating);
        });
    }

    function edit(id) {
        var textTypeId = getSelectedEntityId(id);
        textTypesService.get(textTypeId)
            .then(function (entity) {
                openTextTypeMaintenance(entity, states.updating);
            });
    }

    function isUnprotectedCode() {
        if (!anySelected())
            return false;
        var entity = bulkMenuOperations.selectedRecord(vm.gridOptions.data());
        return entity != null && !entity.isProtected;
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
            click: confirmAndDeleteSelectedTextTypes
        }, {
            id: 'changeTextTypeCode',
            text: 'textType.changeCode.changeTextTypeCode',
            icon: 'cpa-icon cpa-icon-pencil-square-o',
            enabled: isUnprotectedCode,
            click: changeTextTypeCode,
            maxSelection: 1
        }];
    }

    function changeTextTypeCode() {
        openChangeTextTypeCode(bulkMenuOperations.selectedRecord(vm.gridOptions.data()));
    }

    function openChangeTextTypeCode(entity) {
        var changeTextTypeCode = {
            id: entity.id,
            newTextTypeCode: null
        };
        var dialog = modalService.openModal({
            id: 'ChangeTextTypeCode',
            entity: changeTextTypeCode,
            controllerAs: 'vm'
        });
        dialog.then(function () {
            vm.search();
        });
    }

    function confirmAndDeleteSelectedTextTypes() {

        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;

        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelectedTextTypes();
        });
    }

    function deleteSelectedTextTypes() {
        textTypesService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
            function (response) {
                if (response.data.hasError) {
                    var allInUse = bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length === response.data.inUseIds.length;
                    var message = allInUse ? $translate.instant('modal.alert.alreadyInUse') :
                        $translate.instant('modal.alert.partialComplete') + '<br/>' + $translate.instant('modal.alert.alreadyInUse');
                    var title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                    vm.search().then(function () {
                        notificationService.alert({
                            title: title,
                            message: message
                        });
                        textTypesService.markInUseTextTypes(vm.gridOptions.data(), response.data.inUseIds);
                        bulkMenuOperations.selectionChange(vm.gridOptions.data());
                    });
                } else {
                    notificationService.success(response.data.message);
                    vm.search();
                }
            });
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
            combo: 'alt+shift+s',
            description: 'shortcuts.save'
        });

        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.close'
        });

        hotkeys.add({
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                if (modalService.canOpen()) {
                    confirmAndDeleteSelectedTextTypes();
                }
            }
        });
    }
}