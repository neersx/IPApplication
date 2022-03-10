angular.module('inprotech.configuration.general.namerestrictions')
    .controller('NameRestrictionsController', NameRestrictionsController);

function NameRestrictionsController($scope, viewData, kendoGridBuilder, nameRestrictionsService, menuSelection, modalService, notificationService, states, hotkeys, BulkMenuOperations, $translate, $timeout) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'namerestrictions';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.add = add;
        vm.edit = edit;
        vm.duplicate = duplicate;
        vm.deleteSelectedNameRestrictions = deleteSelectedNameRestrictions;
        vm.viewData = viewData;
        vm.nameRestrictions = buildMenu();
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
                nameRestrictionsService.persistSavedNameRestrictions(vm.gridOptions.data());
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            read: doSearch,
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.nameRestrictions" data-context="namerestrictions" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'nameRestriction.description',
                field: 'description',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>'
            }, {
                title: 'nameRestriction.actionToBeTaken',
                field: 'actionToBeTaken',
                sortable: true
            }, {
                title: 'nameRestriction.displayFlag',
                field: 'severity',
                template: '<span ng-if="dataItem.severity" class="cpa-icon cpa-icon-flag debtor-restrictions" ng-class="{ \'error\' : dataItem.severity === \'error\', \'warning\': dataItem.severity === \'warning\', \'info\': dataItem.severity === \'information\' }"></span>'
            }]
        });
    }

    function doSearch() {
        return nameRestrictionsService.search(vm.searchCriteria, vm.gridOptions.getQueryParams());
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
            click: confirmAndDeleteSelectedNameRestrictions
        }];
    }

    function deleteSelectedNameRestrictions() {
        nameRestrictionsService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
            function (response) {
                if (response.data.hasError) {
                    var allInUse = bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length === response.data.inUseIds.length;

                    $translate(['modal.alert.partialComplete', 'modal.alert.alreadyInUse']).then(function (translatedTexts) {
                        var message = allInUse ? translatedTexts['modal.alert.alreadyInUse'] :
                            translatedTexts['modal.alert.partialComplete'] + '<br/>' + translatedTexts['modal.alert.alreadyInUse'];
                        var title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                        vm.gridOptions.search().then(function () {
                            notificationService.alert({
                                title: title,
                                message: message
                            });
                            nameRestrictionsService.markInUseNameRestrictions(vm.gridOptions.data(), response.data.inUseIds);
                            bulkMenuOperations.selectionChange(vm.gridOptions.data());
                        });
                    });
                } else {
                    notificationService.success(response.data.message);
                    vm.gridOptions.search();
                }
            });
    }

    function confirmAndDeleteSelectedNameRestrictions() {
        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;
        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelectedNameRestrictions();
        });
    }

    function openNameRestrictionMaintenance(entity, state) {
        entity.state = state;
        var dialog = modalService.openModal({
            id: 'NameRestrictionsMaintenance',
            entity: entity || {},
            viewData: vm.viewData,
            controllerAs: 'vm',
            dataItem: getEntityFromGrid(entity.id),
            allItems: vm.gridOptions.data()
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
        openNameRestrictionMaintenance(entity, states.adding);
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function edit(id) {
        var nameRestrictionId = getSelectedEntityId(id);
        nameRestrictionsService.get(nameRestrictionId)
            .then(function (entity) {
                openNameRestrictionMaintenance(entity, states.updating);
            });
    }

    function duplicate() {
        var nameRestrictionId = getSelectedEntityId();
        nameRestrictionsService.get(nameRestrictionId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            entityToBeAdded.description = getDescriptionText(entity.description.trim());
            openNameRestrictionMaintenance(entityToBeAdded, states.duplicating);
        });
    }

    function getDescriptionText(description) {
        var appendText = ' - Copy';
        var maxlength = 50 - appendText.length;
        if (description.length > maxlength) {
            description = description.substring(0, maxlength);
        }
        return description + appendText;
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
                    confirmAndDeleteSelectedNameRestrictions();
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