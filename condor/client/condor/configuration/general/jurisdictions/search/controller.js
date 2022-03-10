angular.module('inprotech.configuration.general.jurisdictions').controller('JurisdictionsController', function ($scope, $state, initialData, kendoGridBuilder, jurisdictionsService, modalService, notificationService, hotkeys, BulkMenuOperations, jurisdictionMaintenanceService) {
    'use strict';

    var vm = this;
    var bulkMenuOperations = new BulkMenuOperations('jurisdictionMenu');
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'jurisdictions';
        vm.search = search;
        vm.reset = reset;
        vm.menuInitialised = menuInitialised;
        vm.maintain = maintain;
        vm.openAddModal = openAddModal;
        vm.initShortcuts = initialiseShortcuts;

        vm.permissions = {
            canMaintain: initialData.canMaintain,
            viewOnly: initialData.viewOnly
        };

        vm.menu = buildBulkMenu();
        vm.gridOptions = buildGridOptions();

        init();
    }

    function init() {
        vm.searchCriteria = {};
        reset();
    }

    function reset() {
        vm.gridOptions.clear();
        vm.searchCriteria.text = '';
        vm.menu.clearAll();
    }

    function search() {
        vm.gridOptions.clear();
        vm.gridOptions.search();
        vm.menu.clearAll();
    }

    function maintain(id) {
        $state.go('jurisdictions.detail', {
            id: id
        });
        jurisdictionMaintenanceService.saveResponse = null;
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            pageable: true,
            scrollable: false,
            navigatable: true,
            selectable: 'row',
            selectOnNavigate: true,
            filterOptions: {
                keepFiltersAfterRead: true,
                sendExplicitValues: true
            },
            onSelect: function () {
                var row = vm.gridOptions.selectFocusedRow();
                vm.maintain(row.id);
            },
            read: function (queryParams) {
                return jurisdictionsService.search(vm.searchCriteria, queryParams);
            },
            readFilterMetadata: function (column) {
                return jurisdictionsService.getColumnFilterData(column);
            },
            onDataCreated: function () {
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{error: dataItem.inUse === true && dataItem.selected === true}"',
            columns: [{
                headerTemplate: '<div data-bulk-actions-menu data-context="jurisdictionMenu" data-actions="vm.menu.items" data-on-clear="vm.menu.clearAll()" data-on-select-this-page="vm.menu.selectPage(val)" data-items="vm.gridOptions.data()" data-initialised="vm.menuInitialised()" is-full-selection-possible="false"></div>',
                template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)"></ip-checkbox>',
                width: '35px',
                fixed: true
            }, {
                title: 'jurisdictions.search.code',
                field: 'id',
                width: '10%',
                sortable: true,
                template: '<a ng-click="vm.maintain(dataItem.id)">{{dataItem.id}}</a>'
            }, {
                title: 'jurisdictions.search.name',
                field: 'name',
                sortable: true,
                template: '<a ng-click="vm.maintain(dataItem.id)">{{dataItem.name}}</a>'
            }, {
                title: 'jurisdictions.search.type',
                field: 'type',
                width: '10%',
                sortable: true,
                filterable: true
            }]
        });
    }

    function openAddModal() {
        var dialog = modalService.openModal({
            id: 'CreateJurisdiction',
            controllerAs: 'vm'
        });
        dialog.then(function () {
            notificationService.success();
            vm.maintain(jurisdictionsService.newId);
            vm.search();
        });
    }

    function initialiseShortcuts() {
        if (vm.permissions.canMaintain) {
            hotkeys.add({
                combo: 'alt+shift+i',
                description: 'shortcuts.add',
                callback: function () {
                    if (modalService.canOpen()) {
                        vm.openAddModal();
                    }
                }
            });

            hotkeys.add({
                combo: 'alt+shift+del',
                description: 'shortcuts.delete',
                callback: function () {
                    if (modalService.canOpen() && anySelected()) {
                        deleteJurisdictions();
                    }
                }
            });
        }
    }

    function changeJurisdictionCode() {
        open(bulkMenuOperations.selectedRecord(vm.gridOptions.data()));
    }

    function open(entity) {

        var changeJurisdictionCode = {
            jurisdictionCode: entity.id,
            newJurisdictionCode: null
        };

        var dialog = modalService.openModal({
            id: 'ChangeJurisdictionCode',
            entity: changeJurisdictionCode,
            controllerAs: 'vm'
        });

        dialog.then(function () {
            vm.gridOptions.search();
            bulkMenuOperations.clearAll(vm.gridOptions.data());
        });
    }

    function buildBulkMenu() {
        return {
            context: 'jurisdictionMenu',
            items: [{
                id: 'edit',
                enabled: anySelected,
                maxSelection: 1,
                click: linkToJurisdiction
            }, {
                id: 'delete',
                enabled: anySelected,
                click: deleteJurisdictions
            }, {
                id: 'changeCode',
                text: 'jurisdictions.changeCode.changeJurisdictionCode',
                icon: 'cpa-icon cpa-icon-pencil-square-o',
                enabled: anySelected,
                click: changeJurisdictionCode,
                maxSelection: 1
            }],
            clearAll: function () {
                bulkMenuOperations.clearAll(vm.gridOptions.data());
            },
            selectionChange: function (dataItem) {
                bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
            },
            selectPage: function (val) {
                bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
            }
        };
    }

    function anySelected() {
        return vm.permissions.canMaintain && bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function linkToJurisdiction() {
        var id = _.pluck(_.where(vm.gridOptions.data(), {
            selected: true
        }), 'id');
        vm.maintain(id);
    }

    function deleteJurisdictions() {
        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            var ids = _.pluck(bulkMenuOperations.selectedRecords(), 'id');
            jurisdictionMaintenanceService.delete(ids).then(function (response) {
                if (response.data.result === 'success') {
                    notificationService.success();
                    bulkMenuOperations.clearSelectedItemsArray();
                    vm.gridOptions.search(vm.searchCriteria, vm.gridOptions.queryParams);
                } else {
                    notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: 'modal.alert.alreadyInUse'
                    });
                    vm.gridOptions.search(vm.searchCriteria, vm.gridOptions.queryParams).then(function () {
                        var ids = _.pluck(response.data.errors, 'id');
                        bulkMenuOperations.selectionChange(vm.gridOptions.data(), ids);
                    });

                }
            });
        });
    }

    function menuInitialised() {
        bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
    }
});