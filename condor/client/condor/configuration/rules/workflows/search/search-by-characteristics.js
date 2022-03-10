angular.module('inprotech.configuration.rules.workflows')
    .controller('ipSearchByCharacteristicsController', function (workflowsCharacteristicsService) {
        'use strict';
        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            workflowsCharacteristicsService.initController(vm, 'characteristics', {
                applyTo: null,
                matchType: 'exact-match'
            });

            vm.hasAutofocusOnOffice = vm.hasOffices;
            vm.hasAutofocusOnCaseType = !vm.hasOffices;
        }
    })
    .directive('ipSearchByCharacteristics', function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/search/search-by-characteristics.html',
            scope: {},
            controller: 'ipSearchByCharacteristicsController',
            controllerAs: 'vm'
        };
    });
