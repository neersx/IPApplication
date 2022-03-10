angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceBreakConfirmationController', function ($uibModalInstance, options) {
        'use strict';
        var vm = this;
        vm.parent = options.parent;
        vm.criteriaId = options.criteriaId;
        vm.context = 'workflows.inheritanceBreakConfirmation.' + options.context;

        vm.proceed = proceed;
        vm.cancel = cancel;

        function proceed() {
            $uibModalInstance.close();
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
