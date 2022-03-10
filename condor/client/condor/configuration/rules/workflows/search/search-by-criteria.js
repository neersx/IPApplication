angular.module('inprotech.configuration.rules.workflows')
    .controller('ipSearchByCriteriaController', function (workflowsCharacteristicsService) {
        'use strict';
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            var  charsService = workflowsCharacteristicsService;

            charsService.initController(vm, 'criteria', []);
        }
    })
    .directive('ipSearchByCriteria', function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/search/search-by-criteria.html',
            scope: {},
            controller: 'ipSearchByCriteriaController',
            controllerAs: 'vm'
        };
    });
