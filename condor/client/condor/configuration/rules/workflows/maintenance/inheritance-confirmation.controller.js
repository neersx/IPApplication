angular.module('inprotech.configuration.rules.workflows')
    .controller('InheritanceConfirmationController', function ($scope, $uibModalInstance, store, viewData, $timeout) {
        'use strict';

        var vm = this;
        var applyInheritanceStorageKey;
        vm.$onInit = onInit;

        function onInit() {
            $scope.items = viewData.items;
            $scope.cancel = cancel;
            vm.proceed = proceed;
            vm.translationData = {
                context: viewData.context
            }

            vm.criteriaId = viewData.criteriaId;

            applyInheritanceStorageKey = 'workflows.maintenance.applyInheritance';
            store.session.default(applyInheritanceStorageKey, true);

            vm.inherit = store.session.get(applyInheritanceStorageKey);
        }

        function cancel() {
            $uibModalInstance.dismiss('Cancel');
        }

        function proceed() {
            store.session.set(applyInheritanceStorageKey, vm.inherit);
            $timeout(function () {
                $uibModalInstance.close(vm.inherit);
            });
        }
    });