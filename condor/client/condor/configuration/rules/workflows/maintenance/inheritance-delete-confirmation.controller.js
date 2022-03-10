angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceDeleteConfirmationController', function ($uibModalInstance, store, items) {
        'use strict';

        var vm = this;
        var eventMessagePrefix;
        var entryMessagePrefix;
        var applyInheritanceStorageKey;
        vm.items = items;
        vm.cancel = cancel;
        vm.del = del;
        vm.deleteConfirmationMessage = deleteConfirmationMessage;
        vm.deleteConfirmationDetail = deleteConfirmationDetail;

        eventMessagePrefix = 'workflows.maintenance.deleteConfirmationEvent';
        entryMessagePrefix = 'workflows.maintenance.deleteConfirmationEntry';
        applyInheritanceStorageKey = 'workflows.maintenance.applyInheritance';
        store.session.default(applyInheritanceStorageKey, true);

        vm.applyToDescendants = store.session.get(applyInheritanceStorageKey);

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }

        function del() {
            store.session.set(applyInheritanceStorageKey, vm.applyToDescendants);
            $uibModalInstance.close({
                applyToDescendants: vm.applyToDescendants
            });
        }

        function deleteConfirmationMessage() {
            if (!vm.items || !vm.items.selectedCount) {
                return;
            }

            switch (vm.items.context) {
                case 'event':
                    return eventMessagePrefix +
                        ((vm.items.selectedCount === 1) ? '.messageIndividual' : '.messageMultiple')

                case 'entry':
                    return entryMessagePrefix +
                        ((vm.items.selectedCount === 1) ? '.messageIndividual' : '.messageMultiple')
                default:
                    return;
            }
        }

        function deleteConfirmationDetail() {
            if (!vm.items || !vm.items.selectedCount) {
                return;
            }

            switch (vm.items.context) {
                case 'event':
                    return eventMessagePrefix +
                        ((vm.items.selectedCount === 1) ? '.detailSingleton' : '.detailPlural');
                case 'entry':
                    return entryMessagePrefix +
                        ((vm.items.selectedCount === 1) ? '.detailSingleton' : '.detailPlural');
                default:
                    return;
            }
        }
    });