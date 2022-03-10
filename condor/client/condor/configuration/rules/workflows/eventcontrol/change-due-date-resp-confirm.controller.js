angular.module('inprotech.configuration.rules.workflows')
    .controller('ChangeDueDateRespConfirmController', function ($uibModalInstance, store, options) {
        'use strict';
        var storageKey;
        var vm = this;

        vm.preSave = options.preSave || false; // use pre-save message

        storageKey = 'workflows.eventControl.changeDueDateResp';
        store.session.default(storageKey, true);

        vm.proceed = proceed;
        vm.cancel = cancel;

        vm.changeDueDateResp = store.session.get(storageKey);

        function proceed() {
            store.session.set(storageKey, vm.changeDueDateResp);
            $uibModalInstance.close(vm.changeDueDateResp);
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }
    });
