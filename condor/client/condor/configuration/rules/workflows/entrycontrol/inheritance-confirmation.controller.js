angular.module('inprotech.configuration.rules.workflows')
    .controller('EntryInheritanceConfirmationController', function ($uibModalInstance, store, viewData) {
        'use strict';
        var vm = this;
        var applyInheritanceStorageKey;
        vm.items = viewData.items;
        vm.breakingItems = viewData.breakingItems;

        applyInheritanceStorageKey = 'workflows.entryControl.applyInheritance';
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