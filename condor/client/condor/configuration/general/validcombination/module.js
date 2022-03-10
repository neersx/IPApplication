(function() {
    'use strict';

    angular.module('inprotech.configuration.general.validcombination', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ]);

    angular.module('inprotech.configuration.general.validcombination')
        .run(function(modalService) {
            modalService.register('ValidCombinationMaintenance', 'ValidCombinationMaintenanceController', 'condor/configuration/general/validcombination/validcombination.maintenance.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.validcombination')
        .run(function(modalService) {
            modalService.register('ActionOrder', 'ActionOrderController', 'condor/configuration/general/validcombination/action/action.order.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });

    angular.module('inprotech.configuration.general.validcombination')
        .constant('validCombinationConfig', {
            searchType: {
                default: 'default',
                propertyType: 'propertytype',
                allCharacteristics: 'allcharacteristics',
                category: 'category',
                action: 'action',
                subType: 'subtype',
                basis: 'basis',
                status: 'status',
                dateOfLaw: 'dateoflaw',
                checklist: 'checklist',
                relationship: 'relationship'
            },
            baseStateName: 'validcombination'
        })
        .config(function($stateProvider, validCombinationConfig) {
            $stateProvider.state(validCombinationConfig.baseStateName, {
                    url: '/configuration/general/validcombination',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination.html',
                    controller: 'ValidCombinationController',
                    controllerAs: 'vm',
                    symbol: validCombinationConfig.searchType.default,
                    resolve: {
                        viewData: function($http) {
                            return $http.get('api/configuration/validcombination/viewData').then(function(response) {
                                return response.data;
                            });
                        }
                    },
                    data: {
                        pageTitle: 'Valid Combinations'
                    }
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.allCharacteristics, {
                    url: '/allcharacteristics/:searchKey/:searchName',
                    params: { searchKey: null, searchName: null },
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidJurisdictionController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.allCharacteristics
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.propertyType, {
                    url: '/propertytype',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidPropertyTypeController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.propertyType
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.action, {
                    url: '/action',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidActionController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.action
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.category, {
                    url: '/category',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidCategoryController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.category
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.subType, {
                    url: '/subtype',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidSubTypeController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.subType
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.basis, {
                    url: '/basis',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidBasisController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.basis
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.status, {
                    url: '/status',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidStatusController',
                    controllerAs: 'vc',
                    params: {
                        'status': null
                    },
                    symbol: validCombinationConfig.searchType.status
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.relationship, {
                    url: '/relationship',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidRelationshipController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.relationship
                })
                .state(validCombinationConfig.baseStateName + '.' + validCombinationConfig.searchType.checklist, {
                    url: '/checklist',
                    templateUrl: 'condor/configuration/general/validcombination/validcombination-resultset.html',
                    controller: 'ValidChecklistController',
                    controllerAs: 'vc',
                    symbol: validCombinationConfig.searchType.checklist
                });
        });
}());