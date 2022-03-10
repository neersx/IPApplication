angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceResetConfirmationController', function ($uibModalInstance, viewData) {
        'use strict';
        var vm = this;

        vm.items = viewData.items || [];
        vm.parent = viewData.parent;
        vm.context = 'workflows.inheritanceResetConfirmation.' + viewData.context;

        vm.proceed = proceed;
        vm.cancel = cancel;

        vm.applyChangesToChildren = true;

        function proceed() {
            $uibModalInstance.close(vm.applyChangesToChildren);
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
