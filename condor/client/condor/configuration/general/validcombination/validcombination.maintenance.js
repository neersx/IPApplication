angular.module('inprotech.configuration.general.validcombination')
    .directive('ipValidCombinationMaintenance', function() {
        'use strict';

        return {
            restrict: 'E',
            template: '<ng-include src="vm.templateUrl"/>',
            scope: {},
            controller: '@',
            name: 'controllerName',
            controllerAs: 'vm',
            bindToController: {
                entity: '=',
                maintenance: '=',
                searchCriteria: '=',
                templateUrl: '=',
                clearPicklistModel: '=',
                launchActionOrder: '='
            }
        };
    });
