(function() {
    'use strict';

    angular.module('inprotech.configuration.general.validcombination')
        .controller('ValidDateOfLawController', ValidDateOfLawController);

    ValidDateOfLawController.$inject = ['$scope', 'kendoGridBuilder',
        'validCombinationService'
    ];

    function ValidDateOfLawController($scope, kendoGridBuilder, validCombinationService) {
        var vc = this;
        vc.search = search;
        vc.context = 'dateoflaw';
        vc.gridOptions = buildGridOptions();


        delegate();

        function delegate() {
            $scope.vm.refreshGrid = refreshGrid;
            $scope.vm.search = search;
            $scope.vm.isResetDisabled = isResetDisabled;
            $scope.vm.disableDateOfLawPicklist = disableDateOfLawPicklist;
            $scope.vm.extendPicklistCriteria = extendPicklistCriteria;
        }

        function extendPicklistCriteria(criteria) {
            criteria.propertyType = $scope.vm.searchCriteria.propertyType.key;
            criteria.jurisdiction = _.pluck($scope.vm.searchCriteria.jurisdictions, 'id').join(',');
            return criteria;
        }

        function isResetDisabled() {
            return !$scope.vm.typeaheadErrors.jurisdiction && $scope.vm.selectedSearchOption.type === 'default' && $scope.vm.searchCriteria.jurisdictions.length === 0 && (angular.equals($scope.vm.searchCriteria.propertyType, {}) || $scope.vm.searchCriteria.propertyType.value === '') && (angular.equals($scope.vm.searchCriteria.dateOfLaw, {}) || $scope.vm.searchCriteria.dateOfLaw.value === '') && vc.gridOptions.data().length === 0;
        }

        function search() {
            vc.gridOptions.search();
        }

        function refreshGrid() {
            if (vc.gridOptions.data().length > 0) {
                vc.gridOptions.clear();
            }
        }

        function disableDateOfLawPicklist() {
            return $scope.vm.searchCriteria.jurisdictions.length === 0 || angular.equals($scope.vm.searchCriteria.propertyType, {}) || $scope.vm.searchCriteria.propertyType.value === '';
        }

        $scope.$watch(
            function() {
                return $scope.vm.disableDateOfLawPicklist();
            },
            function(newValue) {
                if (newValue) {
                    $scope.vm.searchCriteria.dateOfLaw = {};
                }
            }
        );

        function buildGridOptions() {

            return kendoGridBuilder.buildOptions($scope, {
                id: 'validCombinationSearchResults',
                pageable: true,
                scrollable: false,
                read: function(queryParams) {
                    var query = buildQuery($scope.vm.searchCriteria);
                    return validCombinationService.search(query, queryParams, vc.context);
                },
                columns: [{
                    title: 'Jurisdiction',
                    field: 'country',
                    width: '16%',
                    sortable: true
                }, {
                    title: 'propertyType',
                    field: 'propertyType',
                    width: '16%',
                    sortable: true
                }, {
                    title: 'Date of Law',
                    field: 'dateOfLaw',
                    width: '10%',
                    sortable: true
                }, {
                    title: 'Retrospective Action',
                    field: 'retrospectiveAction',
                    width: '15%',
                    sortable: true
                }, {
                    title: 'Default Event for Law',
                    field: 'defaultEventForLaw',
                    width: '20%',
                    sortable: true
                }, {
                    title: 'Default Retrospective Event',
                    field: 'defaultRetrospectiveEvent',
                    sortable: true
                }]
            });
        }

        function buildQuery(criteria) {
            return {
                propertyType: criteria.propertyType ? criteria.propertyType.key : null,
                dateOfLaw: criteria.dateOfLaw ? criteria.dateOfLaw.key : null,
                jurisdictions: _.map(criteria.jurisdictions || [], function(j) {
                    return j.id;
                })
            };
        }
    }
})();
