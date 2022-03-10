angular.module('inprotech.configuration.rules.workflows')
    .component('ipInlinePermissionAlert', {
        bindings: {
            options: '<',
            currentPage: '@'
        },
        templateUrl: 'condor/configuration/rules/workflows/directives/inline-permission-alert.html',
        controllerAs: 'vm',
        controller: function() {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                vm.message = vm.options.isNonConfigurableEvent ? 'workflows.common.nonConfigurableEvent' :
                            vm.options.editBlockedByDescendants ? 'workflows.common.hasProtectedDescendents' : 
                            'workflows.common.noRight';
            }
        }
    });
