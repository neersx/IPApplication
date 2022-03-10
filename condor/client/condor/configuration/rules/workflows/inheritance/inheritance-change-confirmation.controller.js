angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceChangeConfirmationController', function ($uibModalInstance, options) {
        'use strict';
        var vm = this;

        vm.proceed = proceed;
        vm.cancel = cancel;
        vm.isReplaceChild = true;
        vm.childCriteriaId = options.childCriteriaId;
        vm.parentCriteriaId = options.parentCriteriaId;
        vm.childName = options.childName;
        vm.parentName = options.parentName;

        function proceed() {
            $uibModalInstance.close({ childCriteriaId: vm.childCriteriaId, parentCriteriaId: vm.parentCriteriaId, isReplaceChild: vm.isReplaceChild });
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
