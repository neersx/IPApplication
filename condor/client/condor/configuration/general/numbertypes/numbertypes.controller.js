angular.module('inprotech.configuration.general.numbertypes')
    .controller('NumberTypesController', NumberTypesController);

function NumberTypesController($scope, kendoGridBuilder, numberTypesService, menuSelection, modalService, notificationService, states, viewData, hotkeys, BulkMenuOperations, $translate, $timeout) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'numbertypes';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.add = add;
        vm.edit = edit;
        vm.duplicate = duplicate;
        vm.viewData = viewData;
        vm.deleteSelectedNumberTypes = deleteSelectedNumberTypes;
        vm.search = doSearch;
        vm.launchNumberTypesPriorityOrder = launchNumberTypesPriorityOrder;
        vm.numberTypes = buildMenu();
        vm.gridOptions = buildGridOptions();
        vm.searchCriteria = {
            text: ''
        };
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
            serverFiltering: true,
            onDataCreated: function () {
                numberTypesService.persistSavedNumberTypes(vm.gridOptions.data());
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            read: doSearch,
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.numberTypes" data-context="numbertypes" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'numberType.code',
                field: 'code',
                width: '130px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.code"></a>'
            }, {
                title: 'numberType.description',
                field: 'description',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>'
            }, {
                title: 'numberType.issuedByIpOffice',
                field: 'issuedByIpOffice',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.issuedByIpOffice" disabled="disabled"></input>'
            }, {
                title: 'numberType.relatedEvent',
                field: 'relatedEvent',
                sortable: true
            }, {
                title: 'numberType.displayPriority',
                field: 'displayPriority',
                sortable: true
            }]
        });
    }

    function doSearch() {
        return numberTypesService.search(vm.searchCriteria, vm.gridOptions.getQueryParams());
    }

    function launchNumberTypesPriorityOrder() {
        var dialog =
            modalService.openModal({
                launchSrc: 'search',
                id: 'NumberTypesOrder',
                controllerAs: 'vm'
            });
        dialog.then(function () {
            vm.gridOptions.search();
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
            click: confirmAndDeleteSelectedNumberTypes
        }, {
            id: 'changeNumberTypeCode',
            text: 'numberType.changeCode.changeNumberTypeCode',
            icon: 'cpa-icon cpa-icon-pencil-square-o',
            enabled: isUnprotectedCode,
            click: changeNumberTypeCode,
            maxSelection: 1
        }];
    }

    function deleteSelectedNumberTypes() {
        numberTypesService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
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
                        numberTypesService.markInUseNumberTypes(vm.gridOptions.data(), response.data.inUseIds);
                        bulkMenuOperations.selectionChange(vm.gridOptions.data());
                    });
                } else {
                    notificationService.success(response.data.message);

                    vm.gridOptions.search();
                }
            });
    }

    function confirmAndDeleteSelectedNumberTypes() {

        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;

        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelectedNumberTypes();
        });
    }

    function openNumberTypeMaintenance(entity, state) {
        entity.state = state;
        var dialog = modalService.openModal({
            id: 'NumberTypeMaintenance',
            entity: entity || {},
            dataItem: getEntityFromGrid(entity.id),
            allItems: vm.gridOptions.data(),
            controllerAs: 'vm',
            searchCallbackFn: vm.gridOptions.search,
            maxNumberTypeLength: vm.viewData.maxNumberTypeLength
        });
        dialog.then(function () {
            vm.gridOptions.search();
        });
    }

    function getEntityFromGrid(id) {
        return _.find(vm.gridOptions.data(), function (item) {
            return item.id === id;
        });
    }

    function add() {
        var entity = {};
        openNumberTypeMaintenance(entity, states.adding);
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function edit(id) {
        var numberTypeId = getSelectedEntityId(id);
        numberTypesService.get(numberTypeId)
            .then(function (entity) {
                openNumberTypeMaintenance(entity, states.updating);
            });
    }

    function changeNumberTypeCode() {
        openChangeNumberTypeCode(bulkMenuOperations.selectedRecord(vm.gridOptions.data()));
    }

    function openChangeNumberTypeCode(entity) {
        var changeNumberTypeCode = {
            id: entity.id,
            numberTypeCode: entity.code,
            newNumberTypeCode: null
        };
        var dialog = modalService.openModal({
            id: 'ChangeNumberTypeCode',
            entity: changeNumberTypeCode,
            controllerAs: 'vm',
            maxNumberTypeLength: vm.viewData.maxNumberTypeLength
        });
        dialog.then(function () {
            vm.gridOptions.search();
        });
    }

    function duplicate() {
        var numberTypeId = getSelectedEntityId();
        numberTypesService.get(numberTypeId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            openNumberTypeMaintenance(entityToBeAdded, states.duplicating);
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
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                if (modalService.canOpen()) {
                    confirmAndDeleteSelectedNumberTypes();
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
    }
}