angular.module('inprotech.picklists')
    .controller('ConfirmPropagateEventChangesController', function ($scope, $uibModalInstance, viewData) {
        'use strict';

        var vm = this;
        vm.proceed = proceed;
        vm.cancel = cancel;
        vm.propagateChanges = false;
        vm.updatedFields = viewData.updatedFields;

        function proceed() {
            $uibModalInstance.close(vm.propagateChanges);
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
