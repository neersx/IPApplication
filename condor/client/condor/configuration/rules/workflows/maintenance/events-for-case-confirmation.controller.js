angular.module('inprotech.configuration.rules.workflows')
    .controller('EventsForCaseConfirmationController', function ($scope, $uibModalInstance, items) {
        'use strict';

        var vm = this;
        var eventMessagePrefix;
        var entryMessagePrefix;

        vm.items = items;
        vm.cancel = cancel;
        vm.proceed = proceed;
        vm.deleteEventConfirmText = deleteEventConfirmText;
        eventMessagePrefix = 'workflows.maintenance.deleteConfirmationEvent';
        entryMessagePrefix = 'workflows.maintenance.deleteConfirmationEntry';

        function deleteEventConfirmText() {
            switch (vm.items.context) {
                case 'event':
                    return eventMessagePrefix +
                        setMessage(vm.items.usedEvents, '.messageConfirmAgainstCasesIndividual',
                            '.messageConfirmAgainstCasesMultiple');
                case 'entry':
                    return entryMessagePrefix +
                        setMessage(vm.items.usedEvents, '.messageConfirmAgainstCasesIndividual',
                            '.messageConfirmAgainstCasesMultiple');
                default:
                    return;
            }
        }
        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }

        function proceed() {
            $uibModalInstance.close('Proceed');
        }

        function setMessage(items, singletonText, pluralText) {
            if (items && items.length > 0) {
                return (items.length === 1) ? singletonText : pluralText;
            }
            return;
        }
    });
