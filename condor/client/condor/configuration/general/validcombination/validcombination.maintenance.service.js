angular.module('inprotech.configuration.general.validcombination')
    .factory('validCombinationMaintenanceService', ValidCombinationMaintenanceService);


function ValidCombinationMaintenanceService(modalService, states, validCombinationService, notificationService, menuSelection, filterFilter, $rootScope, hotkeys, BulkMenuOperations, $translate, $timeout) {
    'use strict';

    var service = {
        vc: {},
        modalOptions: {},
        add: add,
        handleAddFromMainController: handleAddFromMainController,
        savedKeys: [],
        addSavedKeys: addSavedKeys,
        clearSavedRows: clearSavedRows,
        persistSavedData: persistSavedData,
        initialize: initialize,
        bulkMenuClearSelection: bulkMenuClearSelection,
        bulkMenuSelectAll: bulkMenuSelectAll,
        bulkMenuSelectionChange: bulkMenuSelectionChange,
        bulkMenuSelectPage: bulkMenuSelectPage,
        resetBulkMenu: resetBulkMenu,
        edit: edit,
        resetSearchCriteria: resetSearchCriteria,
        prepareDataSource: prepareDataSource
    };

    return service;

    function anyMarked() {
        return service.vc.bulkMenuOperations.anySelected(service.vc.gridOptions.data());
    }

    function initialize(vc, scope) {
        service.modalOptions = {
            viewData: scope.viewData,
            selectedCharacteristic: scope.selectedCharacteristics,
            searchCriteria: vc.searchCriteria || scope.vm.searchCriteria
        };
        service.vc = vc;

        initializeBulkMenuActions();
        $timeout(initShortcuts, 500);
    }

    function resetSearchCriteria(searchCriteria) {
        service.modalOptions.searchCriteria = searchCriteria;
    }

    function initializeBulkMenuActions() {
        _.each(service.vc.actions, function (action) {
            action.enabled = anyMarked;
        });

        var editAction = _.find(service.vc.actions, function (action) {
            return action.id === 'edit';
        });

        if (editAction) {
            editAction.click = edit;
        }

        var duplicateAction = _.find(service.vc.actions, function (action) {
            return action.id === 'duplicate';
        });

        if (duplicateAction) {
            duplicateAction.click = duplicate;
        }

        var deleteAction = _.find(service.vc.actions, function (action) {
            return action.id === 'delete';
        });

        if (deleteAction) {
            deleteAction.click = deleteCombination;
        }
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                if (modalService.canOpen()) {
                    service.vc.add();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                var selectedEntities = getSelectedEntitiesForDelete();

                if (selectedEntities.length > 0 && modalService.canOpen()) {
                    deleteCombination();
                }
            }
        });
    }

    function any(scope) {
        return scope || $rootScope.$new();
    }

    function bulkMenuClearSelection() {
        return service.vc.bulkMenuOperations.clearAll(service.vc.gridOptions.data());
    }

    function bulkMenuSelectAll(val) {
        return service.vc.bulkMenuOperations.selectAll(service.vc.gridOptions.data(), val);
    }

    function bulkMenuSelectPage(val) {
        service.vc.bulkMenuOperations.selectPage(service.vc.gridOptions.data(), val);
    }

    function bulkMenuSelectionChange(dataItem) {
        if (!dataItem) {
            return service.vc.bulkMenuOperations.selectionChange(service.vc.gridOptions.data());
        }

        if (dataItem && dataItem.inUse && dataItem.selected) {
            dataItem.inUse = false;
        }
        return service.vc.bulkMenuOperations.singleSelectionChange(service.vc.gridOptions.data(), dataItem);
    }

    function resetBulkMenu() {
        bulkMenuClearSelection();
        menuSelection.reset(service.vc.context);
        menuSelection.updateData(service.vc.context, null, 0, 0);
    }

    function getSelectedEntityKey() {
        return service.vc.bulkMenuOperations.selectedRecord(service.vc.gridOptions.data()).id;
    }

    function getSelectedEntitiesForDelete() {
        var selections = service.vc.bulkMenuOperations.selectedRecords(service.vc.gridOptions.data());
        return _.pluck(selections, 'id');
    }

    function openValidCombinationMaintenance(entity) {
        modalService.open('ValidCombinationMaintenance', any(), {
            modalOptions: function () {
                return {
                    entity: entity,
                    state: service.modalOptions.state,
                    viewData: service.modalOptions.viewData,
                    selectedCharacteristic: service.modalOptions.selectedCharacteristic,
                    searchCriteria: service.modalOptions.searchCriteria
                };
            }
        }, null, 'vm')
            .then(function () {
                notificationService.success();
                if (service.vc !== undefined) {
                    service.vc.search();
                }
            });
    }

    function add() {
        service.modalOptions.state = states.adding;
        openValidCombinationMaintenance({});
    }

    function handleAddFromMainController() {
        service.modalOptions.state = states.adding;
        modalService.open('ValidCombinationMaintenance', any(), {
            modalOptions: function () {
                return {
                    entity: {},
                    state: service.modalOptions.state,
                    viewData: service.modalOptions.viewData,
                    selectedCharacteristic: service.modalOptions.selectedCharacteristic,
                    searchCriteria: service.modalOptions.searchCriteria
                };
            }
        }, null, 'vm')
            .then(function () {
                notificationService.success();
            });
    }

    function duplicate() {
        validCombinationService.get(getSelectedEntityKey(), service.modalOptions.selectedCharacteristic).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            service.modalOptions.state = states.duplicating;
            openValidCombinationMaintenance(entityToBeAdded);
        });
    }

    function edit(id) {
        var selectedEntityId = id || getSelectedEntityKey();
        validCombinationService.get(selectedEntityId, service.modalOptions.selectedCharacteristic).then(function (entity) {
            service.modalOptions.state = states.updating;
            openValidCombinationMaintenance(entity);
        });
    }

    function deleteCombination() {
        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelected();
        });
    }

    function deleteSelected() {
        validCombinationService.delete(getSelectedEntitiesForDelete(), service.modalOptions.selectedCharacteristic).then(
            function (response) {
                if (response.data.hasError) {
                    var allInUse = service.vc.bulkMenuOperations.selectedRecords(service.vc.gridOptions.data()).length === response.data.inUseIds.length;
                    var message = allInUse ? $translate.instant('modal.alert.alreadyInUse') :
                        $translate.instant('modal.alert.partialComplete') + '<br/>' + $translate.instant('modal.alert.alreadyInUse');
                    var title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                    service.vc.search(false, true).then(function () {
                        notificationService.alert({
                            title: title,
                            message: message
                        });
                    });
                    service.vc.bulkMenuOperations.selectionChange(service.vc.gridOptions.data(), formatIds(response.data.inUseIds));
                } else {
                    notificationService.success(response.data.message);
                    service.vc.bulkMenuOperations.clearSelectedItemsArray();
                    service.vc.search();
                }
            });
    }

    function clearSavedRows() {
        service.savedKeys = [];
    }

    function addSavedKeys(updatedKeys) {
        if (updatedKeys instanceof Array) {
            service.savedKeys = _.union(service.savedKeys, updatedKeys);
        } else {
            service.savedKeys.push(updatedKeys);
        }
    }

    function persistSavedData(searchResults) {
        _.each(searchResults, function (entity) {
            _.each(service.savedKeys, function (savedKey) {
                if (JSON.stringify(entity.id) === JSON.stringify(savedKey)) {
                    entity.saved = true;
                }
            });
        });
    }

    function formatIds(inUseIds) {
        var ids = [];
        if (inUseIds) {
            inUseIds.forEach(function (data) {
                ids.push(getCompositeId(data));
            }, this);
        }
        return ids;
    }
    function prepareDataSource(dataSource) {
        if (dataSource) {
            dataSource.data.forEach(function (data) {
                if (data.id && !data.compositeId) {
                    data.compositeId = getCompositeId(data.id);
                }
            }, this);
        }
        return dataSource;
    }
    function getCompositeId(data) {
        return getValue(data.actionId) + getValue(data.basisId) + getValue(data.categoryId) + getValue(data.checklistId) + getValue(data.statusCode) +
            getValue(data.relationshipCode) + getValue(data.caseCategoryId) + getValue(data.caseTypeId) + getValue(data.countryId) + getValue(data.propertyTypeId) + getValue(data.subTypeId)
    }
    function getValue(value) {
        return (value) ? value : '-'
    }
}