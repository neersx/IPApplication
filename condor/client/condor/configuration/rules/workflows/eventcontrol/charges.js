angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlCharges', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/charges.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope) {
        'use strict';
        var vm = this;
        var viewData;

        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? viewData.parent.charges : {};
            vm.isInherited = isInherited;
            raiseDataCountEvent(viewData);

            _.extend(vm, {
                charges: viewData.charges,
                canEdit: viewData.canEdit
            });

            _.extend(vm.topic, {
                hasError: hasError,
                isDirty: isDirty,
                validate: validate,
                getFormData: getFormData
            });
        }

        function isInherited(objectName) {
            return (vm.parentData) ? angular.equals(vm.charges[objectName], vm.parentData[objectName]) : false;
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function validate() {
            return vm.form.$validate();
        }

        function getFormData() {
            var charge1 = vm.charges.chargeOne;
            var charge2 = vm.charges.chargeTwo;

            return {
                chargeType: charge1.chargeType && charge1.chargeType.key,
                isPayFee: charge1.isPayFee,
                isRaiseCharge: charge1.isRaiseCharge,
                isEstimate: charge1.isEstimate,
                isDirectPay: charge1.isDirectPay,

                chargeType2: charge2.chargeType && charge2.chargeType.key,
                isPayFee2: charge2.isPayFee,
                isRaiseCharge2: charge2.isRaiseCharge,
                isEstimate2: charge2.isEstimate,
                isDirectPay2: charge2.isDirectPay
            }
        }

        function raiseDataCountEvent(viewData) {
            var total = 0;
            if (viewData.charges.chargeOne && viewData.charges.chargeOne.chargeType) {
                total += 1;
            }
            if (viewData.charges.chargeTwo && viewData.charges.chargeTwo.chargeType) {
                total += 1;
            }

            var data = {
                key: vm.topic.key,
                total: total,
                isSubSection: true
            };
            $scope.$emit('topicItemNumbers', data);
        }
    }
});