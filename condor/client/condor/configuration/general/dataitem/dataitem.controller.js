angular.module('inprotech.configuration.general.dataitem')
    .controller('DataItemController', DataItemController);

function DataItemController($scope, kendoGridBuilder, menuSelection, dataItemService, dateService, notificationService, $timeout, modalService, BulkMenuOperations, hotkeys, states, $translate, pagerHelperService) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'dataitems';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.gridOptions = buildGridOptions();
        vm.clearAll = clearAll;
        vm.resetSearchCriteria = resetSearchCriteria;
        vm.deleteSelectedDataItems = deleteSelectedDataItems;
        vm.highlightFilteredGroup = highlightFilteredGroup;
        vm.dataItems = buildMenu();
        vm.search = search;
        vm.totalItems = null;
        vm.add = add;
        vm.edit = edit;
        vm.lastNavigatedId = null;

        resetSearchCriteria();

        $timeout(initShortcuts, 500);
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            pageable: true,
            scrollable: false,
            navigatable: true,
            detailTemplate: '<ipt-dataitem-detail-view data-parent="dataItem"></ipt-dataitem-detail-view>',
            rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
            autoGenerateRowTemplate: true,
            selectable: 'row',
            showExpandAll: true,
            onDataCreated: function () {
                dataItemService.persistSavedDataItems(vm.gridOptions.data());
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            read: function (queryParams) {
                return dataItemService.search(vm.searchCriteria, queryParams).then(function (response) {
                    vm.totalItems = response.ids;
                    return response.results;
                });
            },
            dataBound: function (e) {
                $timeout(selectAndScroll, 10, true, e);
            },
            filterOptions: {
                keepFiltersAfterRead: true,
                sendExplicitValues: true
            },
            readFilterMetadata: function (column) {
                return dataItemService.getColumnFilterData(column);
            },
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.dataItems" data-context="dataitems" data-on-clear="vm.clearAll();" is-full-selection-possible="false" data-on-select-this-page="vm.selectPage(val)" data-initialised="vm.menuInitialised()"></div>'
            }, {
                title: 'dataItem.name',
                field: 'name',
                width: '15%',
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.name"></a>',
                sortable: true
            }, {
                title: 'dataItem.description',
                field: 'description',
                width: '15%',
                sortable: true
            }, {
                title: 'dataItem.outputDataType',
                field: 'outputDataType',
                width: '20%',
                sortable: false
            }, {
                title: 'dataItem.updateDate',
                field: 'dateUpdated',
                width: '15%',
                sortable: true,
                filterable: {
                    type: 'date'
                },
                template: '<span>{{ dataItem.dateUpdated | localeDate }}</span>'
            }, {
                title: 'dataItem.creationDate',
                field: 'dateCreated',
                width: '15%',
                sortable: true,
                filterable: {
                    type: 'date'
                },
                template: '<span>{{ dataItem.dateCreated | localeDate }}</span>'
            }, {
                title: 'dataItem.createdBy',
                field: 'createdBy',
                width: '15%',
                sortable: true,
                filterable: true
            }, {
                title: 'dataItem.group',
                field: 'name',
                width: '15%',
                sortable: false,
                template: '<span ng-if= "dataItem.groups.length > 0"> <span ng-repeat="group in dataItem.groups track by $index"><span ng-if="$index > 0">, </span><span ng-style="{\'font-weight\': vm.highlightFilteredGroup(group)}">{{group.value}}</span></span></span>'
            }]
        });
    }

    function search() {
        vm.gridOptions.clear();
        vm.gridOptions.search();
        vm.clearAll();
    }

    function highlightFilteredGroup(group) {
        if (vm.searchCriteria.group !== null && group !== undefined) {
            if (_.any(vm.searchCriteria.group, function (item) {
                return (item.key === group.code);
            }))
                return 'bold';
        }
    }

    function resetSearchCriteria() {
        vm.gridOptions.clear();
        vm.searchCriteria = {};
        vm.clearAll();
    }

    function add() {
        var entity = {
            isSqlStatement: true
        };
        openDataItemMaintenance(entity, states.adding);
    }

    function openDataItemMaintenance(entity, state) {
        entity.state = state;
        modalService.openModal({
            id: 'DataItemMaintenanceConfig',
            entity: entity || {},
            dataItem: getEntityFromGrid(entity.id),
            allItems: vm.totalItems,
            controllerAs: 'vm'
        }).then(function (data) {
            vm.lastNavigatedId = data.dataItemId;
            goToPageForDataItem(data.dataItemId, data.shouldRefresh);
        });
    }

    function goToPageForDataItem(dataItemId, shouldRefresh) {
        var newPage = pagerHelperService.getPageForId(_.pluck(vm.totalItems, 'id'), dataItemId, vm.gridOptions.pageable.pageSize);
        if (shouldRefresh || (newPage && vm.gridOptions.dataSource.page() !== newPage.page)) {
            vm.gridOptions.dataSource.page(newPage.page);
            clearAll();
        } else {
            vm.gridOptions.selectLastNavigatedItem(vm.lastNavigatedId, 'checkbox_row_' + vm.lastNavigatedId);
        }
    }

    function selectAndScroll() {
        vm.gridOptions.selectLastNavigatedItem(vm.lastNavigatedId, 'checkbox_row_' + vm.lastNavigatedId);
    }

    function getEntityFromGrid(id) {
        return _.find(vm.gridOptions.data(), function (item) {
            return item.id === id;
        });
    }

    function clearAll() {
        return bulkMenuOperations.clearAll(vm.gridOptions.data());
    }

    vm.selectPage = function (val) {
        bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
    }

    vm.menuInitialised = function () {
        bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
    };

    vm.selectionChange = function (dataItem) {
        if (dataItem && dataItem.inUse && dataItem.selected) {
            dataItem.inUse = false;
        }
        return bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
    };

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function edit(id) {
        var dataItemId = getSelectedEntityId(id);
        dataItemService.get(dataItemId)
            .then(function (entity) {
                openDataItemMaintenance(entity, states.updating);
            });
    }

    function duplicate() {
        var dataItemId = getSelectedEntityId();
        dataItemService.get(dataItemId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            openDataItemMaintenance(entityToBeAdded, states.duplicating);
        });
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
            click: confirmAndDeleteSelectedDataItems
        }];
    }

    function confirmAndDeleteSelectedDataItems() {

        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;

        notificationService.confirmDelete({
            message: 'dataItem.confirmDelete'
        }).then(function () {
            deleteSelectedDataItems();
        });
    }

    function deleteSelectedDataItems() {
        dataItemService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
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
                        bulkMenuOperations.selectionChange(vm.gridOptions.data(), response.data.inUseIds);
                    });
                } else {
                    notificationService.success(response.data.message);
                    bulkMenuOperations.clearSelectedItemsArray();
                    vm.gridOptions.search();
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
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                if (modalService.canOpen()) {
                    confirmAndDeleteSelectedDataItems();
                }
            }
        });
    }
}