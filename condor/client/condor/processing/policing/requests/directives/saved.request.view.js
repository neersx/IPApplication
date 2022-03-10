angular.module('inprotech.processing.policing')
    .controller('ipSavedRequestViewController', ipSavedRequestViewController)
    .component('ipSavedRequestView', {
        controller: 'ipSavedRequestViewController',
        controllerAs: 'vm',
        bindings: {
            viewData: '=',
            topic: '='
        },
        templateUrl: 'condor/processing/policing/requests/directives/saved.request.view.html'
    });


ipSavedRequestViewController.$inject = ['$scope', '$translate', 'kendoGridBuilder', 'modalService', 'policingRequestService', 'BulkMenuOperations', 'notificationService', 'localSettings'];

function ipSavedRequestViewController($scope, $translate, kendoGridBuilder, modalService, policingRequestService, BulkMenuOperations, notificationService, localSettings) {

    'use strict';
    var vm = this;
    var bulkMenuOperations;
    var service;
    vm.$onInit = onInit;

    function onInit() {
        vm.context = 'policingRequest';
        bulkMenuOperations = new BulkMenuOperations(vm.context);
        service = policingRequestService;
        vm.topic.initialised = true;
        vm.onClickAdd = addRequest;
        service.savedRequestIds.splice(0, service.savedRequestIds.length);
        initializeActions();
    }

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    var updateData = function (requests, notDeletedIds) {
        return vm.gridOptions.search().then(function () {
            notDeletedIds ? bulkMenuOperations.selectionChange(vm.gridOptions.data(), notDeletedIds) : vm.clearAll();
        });
    };

    var openMaintenanceDialog = function (request) {
        modalService.open('PolicingRequestMaintain', $scope, {
            request: request,
            canCalculateAffectedCases: vm.viewData.canCalculateAffectedCases
        }).then(function (result) {
            if (result === 'Success') {
                updateData(vm.gridOptions.data());
            }
        });
    };

    var duplicate = function () {
        var requestId = getSelectedEntityId();
        service.getRequest(requestId).then(function (request) {
            request.requestId = null;
            request.title = request.title + ' - Copy';
            openMaintenanceDialog(request);
        });
    };

    vm.openSelectedRequest = function (requestId) {
        requestId = getSelectedEntityId(requestId);
        openMaintenanceDialog(service.getRequest(requestId));
    };

    function getSelectedEntityId(id) {
        if (id !== undefined && id !== null) {
            return id;
        }
        return bulkMenuOperations.selectedRecord(vm.gridOptions.data()).id;
    }

    vm.deleteSelected = function () {
        notificationService.confirmDelete({
            message: 'modal.confirmDelete.message'
        }).then(function () {
            service.delete(_.pluck(bulkMenuOperations.selectedRecords(vm.gridOptions.data()), 'id')).then(function (res) {
                if (res.data.status == 'success') {
                    notificationService.success();
                    bulkMenuOperations.clearSelectedItemsArray();
                    vm.gridOptions.search();
                } else if (res.data.status == 'partialSuccess') {
                    var partialCompleteMessage = $translate.instant('modal.alert.partialComplete') + '<br/>' + $translate.instant('modal.alert.alreadyInUse');

                    updateData(vm.gridOptions.data(), res.data.notDeletedIds);

                    notificationService.alert({
                        title: 'modal.partialComplete',
                        message: partialCompleteMessage
                    }, $scope);
                } else if (res.data.status == 'error') {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data(), res.data.notDeletedIds);

                    notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: 'policing.request.maintenance.errors.' + res.data.error
                    }, $scope);
                }
            });
        });
    };

    vm.selectPage = function (val) {
        bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
    };

    vm.clearAll = function () {
        return bulkMenuOperations.clearAll(vm.gridOptions.data());
    }

    vm.runNowSelected = function () {
        var requestId = getSelectedEntityId();
        var request = service.getRequest(requestId);
        modalService.open('PolicingRequestRunNowConfirmation', $scope, {
            request: request,
            canCalculateAffectedCases: vm.viewData.canCalculateAffectedCases
        }).then(function (result) {
            if (result.runType) {
                service.runNow(requestId, result.runType).then(function () {
                    notificationService.success('policing.request.runNow.success');
                    vm.clearAll();
                });
            }
        });
    };

    function initializeActions() {
        vm.actions = [{
            id: 'runNow',
            icon: 'cpa-icon cpa-icon-gears',
            text: 'policing.request.action.runNow',
            enabled: anySelected,
            maxSelection: 1,
            click: vm.runNowSelected
        }, {
            id: 'edit',
            enabled: anySelected,
            maxSelection: 1,
            click: function () {
                vm.openSelectedRequest();
            }
        }, {
            id: 'duplicate',
            enabled: anySelected,
            click: duplicate,
            maxSelection: 1
        }, {
            id: 'delete',
            enabled: anySelected,
            click: vm.deleteSelected
        }];
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

    vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'savedRequestsGrid',
        pageable: {
            pageSize: localSettings.Keys.policing.savedRequests.pageNumber.getLocal
        },
        onPageSizeChanged: function (pageSize) {
            localSettings.Keys.policing.savedRequests.pageNumber.setLocal(pageSize);
        },
        scrollable: false,
        autoBind: true,
        resizable: true,
        reorderable: false,
        navigatable: true,
        selectable: 'row',
        autoGenerateRowTemplate: true,
        rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
        onSelect: function () {
            vm.gridOptions.clickHyperlinkedCell();
        },
        read: function (queryParams) {
            return service.getRequests(queryParams);
        },
        onDataCreated: function () {
            service.uiPersistSavedRequests(vm.gridOptions.data());
            bulkMenuOperations.selectionChange(vm.gridOptions.data());
        },
        columns: getColumns()
    });


    function getColumns() {
        return [{
            field: 'bulkMenu',
            headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.actions" data-context="policingRequest" data-on-clear="vm.clearAll()" is-full-selection-possible="false" data-on-select-this-page="vm.selectPage(val)" data-initialised="vm.menuInitialised()"></div>',
            template: '<ip-checkbox ng-model="dataItem.selected" data-ng-id="{{dataItem.id}}" ng-change="vm.selectionChange(dataItem)">',
            sortable: false,
            width: '20px',
            locked: true
        }, {
            title: 'policing.management.savedrequests.request-title',
            field: 'title',
            template: '<a ng-click="vm.openSelectedRequest(dataItem.id)">{{ dataItem.title }}</a>',
            sortable: true
        }, {
            title: 'policing.management.savedrequests.notes',
            field: 'notes',
            sortable: true
        }];
    }

    function addRequest() {
        openMaintenanceDialog(null);
    }
}