angular.module('inprotech.configuration.general.validcombination')
    .controller('ValidChecklistController', ValidChecklistController);



function ValidChecklistController($scope, kendoGridBuilder, validCombinationService, validCombinationMaintenanceService, BulkMenuOperations) {
    'use strict';

    var vc = this;
    vc.search = search;
    vc.context = 'checklist';
    vc.bulkMenuOperations = new BulkMenuOperations(vc.context);
    vc.actions = $scope.vm.actions;
    vc.add = handleAdd;
    vc.launchEdit = launchEdit;
    vc.noResultsHint = '';
    vc.gridOptions = buildGridOptions();

    delegate();
    validCombinationMaintenanceService.initialize(vc, $scope);

    function delegate() {
        $scope.vm.refreshGrid = refreshGrid;
        $scope.vm.search = search;
        $scope.vm.isResetDisabled = isResetDisabled;
    }

    function isResetDisabled() {
        return $scope.vm.form.$valid && $scope.vm.selectedSearchOption.type === 'default' && ($scope.vm.searchCriteria.jurisdictions === null || $scope.vm.searchCriteria.jurisdictions.length === 0) && (angular.equals($scope.vm.searchCriteria.propertyType, {}) || $scope.vm.searchCriteria.propertyType === null) && (angular.equals($scope.vm.searchCriteria.caseType, {}) || $scope.vm.searchCriteria.caseType === null) && (angular.equals($scope.vm.searchCriteria.checklist, {}) || $scope.vm.searchCriteria.checklist === null) && vc.gridOptions.data().length === 0;
    }

    function search(resetSavedData, preventPageReset) {
        return vc.gridOptions.search({
            preventPageReset: preventPageReset
        }).then(function() {
            if (resetSavedData) {
                validCombinationMaintenanceService.clearSavedRows();
            }
            noResultsHint();
        });
    }

    function noResultsHint() {
        if (vc.gridOptions.data().length === 0) {
            vc.noResultsHint = $scope.vm.containsDefault() ? null : $scope.vm.noResultsHint();
        }
    }

    function refreshGrid() {
        if (vc.gridOptions.data().length > 0) {
            vc.gridOptions.clear();
            validCombinationMaintenanceService.resetBulkMenu();
        }
    }

    function buildGridOptions() {

        return kendoGridBuilder.buildOptions($scope, {
            id: 'validCombinationSearchResults',
            pageable: true,
            scrollable: false,
            reorderable: false,
            navigatable: true,
            selectable: 'row',
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
            read: function(queryParams) {
                var query = buildQuery($scope.vm.searchCriteria);
                return validCombinationService.search(query, queryParams, vc.context).then(function(data) {
                    return validCombinationMaintenanceService.prepareDataSource(data);
                });
            },
            onDataCreated: function() {
                vc.selectionChange();
                validCombinationMaintenanceService.persistSavedData(vc.gridOptions.data()).then(function(data) {
                    return vc.prepareDataSource(data);
                });
            },
            columns: [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vc.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vc.gridOptions.data()" data-actions="vc.actions" data-context="checklist" data-on-clear="vc.clearSelection();" is-full-selection-possible="false" data-on-select-this-page="vc.selectPage(val)" data-initialised="vc.menuInitialised()"></div>'
            }, {
                title: 'Case Type',
                field: 'caseType',
                width: '15%',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'Jurisdiction',
                field: 'country',
                width: '20%',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'propertyType',
                field: 'propertyType',
                width: '15%',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'Checklist',
                field: 'checklist',
                width: '16%',
                sortable: true,
                oneTimeBinding: true
            }, {
                title: 'Valid Description',
                field: 'validDescription',
                sortable: true,
                oneTimeBinding: true,
                template: '<a ng-click="vc.launchEdit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.validDescription"></a>'
            }]
        });
    }

    function buildQuery(criteria) {
        return {
            propertyType: criteria.propertyType ? criteria.propertyType.code : null,
            jurisdictions: _.map(criteria.jurisdictions || [], function(j) {
                return j.code;
            }),
            caseType: criteria.caseType ? criteria.caseType.code : null,
            checklist: criteria.checklist ? criteria.checklist.code : null
        };
    }

    function launchEdit(id) {
        validCombinationMaintenanceService.edit(id);
    }
    vc.clearSelection = function() {
        validCombinationMaintenanceService.bulkMenuClearSelection();
    };

    vc.selectAll = function(val) {
        return validCombinationMaintenanceService.bulkMenuSelectAll(val);
    };

    vc.selectPage = function(val) {
        validCombinationMaintenanceService.bulkMenuSelectPage(val);
    }

    vc.selectionChange = function(dataItem) {
        validCombinationMaintenanceService.bulkMenuSelectionChange(dataItem);
    };

    vc.menuInitialised = function() {
        vc.bulkMenuOperations.initialiseMenuForPaging(vc.gridOptions.pageable.pageSize);
    };

    function handleAdd() {
        validCombinationMaintenanceService.add();
    }
}