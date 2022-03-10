angular.module('inprotech.configuration.general.status')
    .controller('StatusController', StatusController);


function StatusController($state, $scope, kendoGridBuilder, supportData, menuSelection, statusService, modalService, notificationService, states, hotkeys, validCombinationConfig, BulkMenuOperations, $translate, $timeout) {
    'use strict';

    var vm = this;
    var bulkMenuOperations
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'status';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        vm.resetSearchCriteria = resetSearchCriteria;
        vm.resetFilterCriteria = resetFilterCriteria;
        vm.toggleFilterOption = toggleFilterOption;
        vm.addStatus = addStatus;
        vm.actions = buildMenu();
        vm.edit = edit;
        vm.maintainValidCombination = maintainValidCombination;
        vm.duplicate = duplicate;
        vm.deleteSelectedStatus = deleteSelectedStatus;
        vm.gridOptions = buildGridOptions();

        resetSearchCriteria();
        resetFilterCriteria();
        $timeout(initShortcuts, 500);

        vm.supportData = {
            stopPayReasons: supportData.stopPayReasons,
            permissions: supportData.permissions
        };
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            scrollable: false,
            reorderable: false,
            navigatable: true,
            selectable: 'row',
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
            serverFiltering: false,
            onDataCreated: function () {
                statusService.persistSavedStatuses(vm.gridOptions.data());
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            autoBind: true,
            read: search,
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.actions" data-context="status" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'status.internalDesc',
                field: 'name',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.name"></a>'
            }, {
                title: 'status.externalDesc',
                field: 'externalName',
                sortable: true
            }, {
                title: 'Code',
                field: 'id',
                sortable: true
            }, {
                title: 'status.noOfCases',
                field: 'noOfCases',
                sortable: true
            }, {
                title: 'status.pending',
                field: 'isPending',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isPending" disabled="disabled"></input>'
            }, {
                title: 'status.registered',
                field: 'isRegistered',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isRegistered" disabled="disabled"></input>'
            }, {
                title: 'status.dead',
                field: 'isDead',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isDead" disabled="disabled"></input>'
            }, {
                title: 'status.stopPayReason',
                field: 'stopPayReasonDesc',
                sortable: true
            }]
        });
    }    

    function search() {
        vm.searchCriteria.isRenewal = vm.filterCriteria.forRenewal;
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        return statusService.search(vm.searchCriteria);
    }

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function canEdit() {
        return vm.supportData.permissions.canUpdate && anySelected();
    }

    function canCreate() {
        return vm.supportData.permissions.canCreate && anySelected();
    }

    function canDelete() {
        return vm.supportData.permissions.canDelete && anySelected();
    }

    function canMaintainValidStatus() {
        return vm.supportData.permissions.canMaintainValidCombination && anySelected();
    }

    function buildMenu() {
        return [{
            id: 'edit',
            enabled: canEdit,
            click: edit,
            maxSelection: 1
        }, {
            id: 'duplicate',
            enabled: canCreate,
            click: duplicate,
            maxSelection: 1
        }, {
            id: 'delete',
            enabled: canDelete,
            click: confirmAndDeleteSelectedStatus
        }, {
            id: 'maintainValidCombination',
            text: 'Valid Status',
            icon: 'cpa-icon cpa-icon-pencil-square-o',
            enabled: canMaintainValidStatus,
            maxSelection: 1,
            click: maintainValidCombination
        }];
    }

    function deleteSelectedStatus() {
        statusService.delete(bulkMenuOperations.selectedRecords(vm.gridOptions.data())).then(
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
                            statusService.markInUseStatuses(vm.gridOptions.data(), response.data.inUseIds);
                        });
                    });
                } else {
                    notificationService.success(response.data.message);
                    vm.gridOptions.search();
                    menuSelection.reset('status');
                }
            });
    }

    function confirmAndDeleteSelectedStatus() {
        if (bulkMenuOperations.selectedRecords(vm.gridOptions.data()).length <= 0) return;
        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            deleteSelectedStatus();
        });
    }

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    function edit(id) {
        var statusId = (id === undefined || id === null) ? getSelectedEntityId() : id;
        statusService.get(statusId).then(function (entity) {
            openStatusMaintenance(entity, states.updating);
        });
    }

    function duplicate() {
        var statusId = getSelectedEntityId();
        statusService.get(statusId).then(function (entity) {
            var entityToBeAdded = angular.copy(entity);
            entityToBeAdded.id = null;
            entityToBeAdded.name = getDescriptionText(entity.name.trim());
            openStatusMaintenance(entityToBeAdded, states.duplicating);
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

    vm.selectionChange = function (dataItem) {
        if (dataItem && dataItem.inUse && dataItem.selected) {
            dataItem.inUse = false;
        }
        return bulkMenuOperations.selectionChange(vm.gridOptions.data());
    };

    vm.clearAll = function () {
        return bulkMenuOperations.clearAll(vm.gridOptions.data());
    };

    vm.selectAll = function (val) {
        return bulkMenuOperations.selectAll(vm.gridOptions.data(), val);
    };

    function resetSearchCriteria() {
        vm.searchCriteria = {
            text: '',
            isRenewal: false
        };

        resetFilterCriteria();
    }

    function resetFilterCriteria() {
        vm.filterCriteria = {
            forCase: true,
            forRenewal: false
        };
    }

    function toggleFilterOption(option) {
        if (option === 'forCase') {
            vm.filterCriteria.forCase = true;
            vm.filterCriteria.forRenewal = false;
        } else {
            vm.filterCriteria.forRenewal = true;
            vm.filterCriteria.forCase = false;
        }
        vm.gridOptions.search();
    }

    function openStatusMaintenance(entity, state) {
        entity.state = state;
        var dialog = modalService.openModal({
            id: 'StatusMaintenance',
            entity: entity,
            supportData: vm.supportData,
            controllerAs: 'vm'
        });
        dialog.then(function (isRenewal) {
            if (isRenewal) {
                toggleFilterOption('forRenewal');
            } else {
                toggleFilterOption('forCase');
            }

            notificationService.success();
            vm.gridOptions.search();
        });
    }

    function addStatus() {
        var entity = {
            statusType: vm.filterCriteria.forRenewal ? 'renewal' : 'case',
            statusSummary: 'pending'
        };
        openStatusMaintenance(entity, states.adding);
    }

    function maintainValidCombination() {
        var selectedStatus = bulkMenuOperations.selectedRecord(vm.gridOptions.data());
        $state.go(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.status, {
            'status': selectedStatus
        });
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                if (modalService.canOpen()) {
                    vm.addStatus();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+del',
            description: 'shortcuts.delete',
            callback: function () {
                confirmAndDeleteSelectedStatus();
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