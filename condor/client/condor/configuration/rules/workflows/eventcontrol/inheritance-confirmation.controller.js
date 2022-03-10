angular.module('inprotech.configuration.rules.workflows')
    .controller('EventInheritanceConfirmationController', function ($uibModalInstance, store, viewData) {
        'use strict';
        var vm = this;
        var applyInheritanceStorageKey;
        vm.items = viewData.items || [];

        applyInheritanceStorageKey = 'workflows.eventControl.applyInheritance';
        store.session.default(applyInheritanceStorageKey, true);

        vm.proceed = proceed;
        vm.cancel = cancel;

        vm.applyChangesToChildren = store.session.get(applyInheritanceStorageKey);

        function proceed() {
            store.session.set(applyInheritanceStorageKey, vm.applyChangesToChildren);
            $uibModalInstance.close(vm.applyChangesToChildren);
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
