angular.module('inprotech.configuration.rules.workflows').directive('ipWorkflowsEntryControlUserAccessUsers', function () {
    'use strict';

    return {
        restrict: 'E',
        scope: {
            roleId: '@'
        },
        templateUrl: 'condor/configuration/rules/workflows/entrycontrol/directives/roleUsers.html',
        controller: function ($scope, workflowsEntryControlService) {
            var vm = this;
            vm.$onInit = onInit;

            function onInit() {

                workflowsEntryControlService.getUsers($scope.roleId).then(function (data) {
                    vm.users = data;
                });
            }
        },
        controllerAs: 'vm'
    };
});
