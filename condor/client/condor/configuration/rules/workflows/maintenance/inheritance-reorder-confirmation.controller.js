angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceReorderConfirmationController', function ($uibModalInstance, items) {
        'use strict';

        var vm = this;

        vm.items = items;
        vm.cancel = cancel;
        vm.proceed = proceed;

        function cancel() {
            $uibModalInstance.dismiss();
        }

        function proceed() {
            $uibModalInstance.close();
        }
    });
