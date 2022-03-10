angular.module('inprotech.configuration.general.validcombination')
    .directive('ipCopyValidCombination', function() {
        'use strict';

        return {
            restrict: 'E',
            template: '<ng-include src="vm.template"/>',
            scope: {},
            controller: '@',
            name: 'controllerName',
            controllerAs: 'vm',
            bindToController: {
                copyEntity: '=',
                maintenance: '=',
                enableCopySave: '=',
                template: '='
            }
        };
    });