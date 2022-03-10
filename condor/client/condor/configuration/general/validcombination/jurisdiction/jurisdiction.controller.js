angular.module('inprotech.configuration.general.validcombination')
    .controller('ValidJurisdictionController', ValidJurisdictionController);


function ValidJurisdictionController($scope, $stateParams, kendoGridBuilder, validCombinationService) {
    'use strict';

    var vc = this;
    vc.search = search;
    vc.context = 'jurisdiction';
    vc.noResultsHint = '';
    vc.gridOptions = buildGridOptions();

    delegate();

    function delegate() {
        $scope.vm.refreshGrid = refreshGrid;
        $scope.vm.search = search;
        $scope.vm.isResetDisabled = isResetDisabled;
        if ($stateParams.searchKey) {
            $scope.vm.searchCriteria.jurisdictions.push({ 'key': $stateParams.searchKey, 'code': $stateParams.searchKey, 'value': $stateParams.searchName });
        }
    }

    function isResetDisabled() {
        return $scope.vm.form.$valid && $scope.vm.selectedSearchOption.type === 'default' && ($scope.vm.searchCriteria.jurisdictions === null || $scope.vm.searchCriteria.jurisdictions.length === 0) && vc.gridOptions.data().length === 0;
    }

    function search() {
        vc.gridOptions.search().then(function() {
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
        }
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'validCombinationSearchResults',
            pageable: true,
            scrollable: false,
            navigatable: true,
            selectable: 'row',
            autoBind: $stateParams.searchKey,
            read: function(queryParams) {
                var query = buildQuery($scope.vm.searchCriteria);
                return validCombinationService.search(query, queryParams, vc.context);
            },
            columns: [{
                title: 'Jurisdiction',
                field: 'country',
                width: '10%',
                sortable: true
            }, {
                title: 'Case Type',
                field: 'caseType',
                width: '10%',
                sortable: true
            }, {
                title: 'propertyType',
                field: 'propertyType',
                width: '10%',
                sortable: true
            }, {
                title: 'Action',
                field: 'action',
                width: '10%',
                sortable: true
            }, {
                title: 'Case Category',
                field: 'category',
                width: '10%',
                sortable: true
            }, {
                title: 'Sub Type',
                field: 'subType',
                width: '10%',
                sortable: true
            }, {
                title: 'Basis',
                field: 'basis',
                width: '10%',
                sortable: true
            }, {
                title: 'Status',
                field: 'status',
                width: '9%',
                sortable: true
            }, {
                title: 'Checklist',
                field: 'checklist',
                width: '10%',
                sortable: true
            }, {
                title: 'Case Relationship',
                field: 'relationship',
                sortable: true
            }]
        });
    }

    function buildQuery(criteria) {
        return {
            jurisdictions: _.map(criteria.jurisdictions || [], function(j) {
                return j.code;
            })
        };
    }
}