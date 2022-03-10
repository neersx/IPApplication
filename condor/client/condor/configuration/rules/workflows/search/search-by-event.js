angular.module('inprotech.configuration.rules.workflows')
    .controller('ipSearchByEventController', function (workflowsCharacteristicsService) {
        'use strict';
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            var charsService = workflowsCharacteristicsService;

            charsService.initController(vm, 'event', {
                applyTo: null,
                matchType: 'exact-match'
            });
        }
    })
    .directive('ipSearchByEvent', function () {
        'use strict';

        return {
            restrict: 'E',
            templateUrl: 'condor/configuration/rules/workflows/search/search-by-event.html',
            scope: {},
            controller: 'ipSearchByEventController',
            controllerAs: 'vm'
        };
    });
