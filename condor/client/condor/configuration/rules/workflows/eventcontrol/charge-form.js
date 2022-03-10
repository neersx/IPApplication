angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlChargeForm', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/charge-form.html',
    bindings: {
        canEdit: '<',
        chargeTypeLabel: '@?',
        form: '=',
        charge: '=',
        wrapOptions: '@'
    },
    controllerAs: 'vm',
    controller: function () {
        'use strict';
        var vm = this;
        var allCheckboxes = ['isRaiseCharge', 'isEstimate', 'isDirectPay', 'isPayFee'];
        var mutuallyExclusiveCheckboxes = ['isPayFee', 'isEstimate'];

        vm.$onInit = onInit;

        function onInit() {

            _.extend(vm, {
                onload: onload,
                onChargeTypeChanged: onChargeTypeChanged,
                onPayFeeChanged: onPayFeeChanged,
                onRaiseChargeChanged: onRaiseChargeChanged,
                onEstimateChanged: onEstimateChanged,
                onDirectPayChange: onDirectPayChange,
                keepCheckedIfOnlyOneChecked: keepCheckedIfOnlyOneChecked,
                uncheckMutuallyExclusive: uncheckMutuallyExclusive,
                isCheckboxDisabled: isCheckboxDisabled,
                isDirectPayDisabled: isDirectPayDisabled
            });

            onload();
        }

        function onload() {
            vm.chargeTypeLabel = vm.chargeTypeLabel || 'picklist.chargeType';
            vm.onChargeTypeChanged();
        }        

        function onChargeTypeChanged() {
            if (!(vm.charge.chargeType && vm.charge.chargeType.key)) {
                vm.charge.isPayFee = false;
                vm.charge.isRaiseCharge = false;
                vm.charge.isEstimate = false;
                vm.charge.isDirectPay = false;
            } else {
                if (!vm.charge.isPayFee &&
                    !vm.charge.isRaiseCharge &&
                    !vm.charge.isEstimate &&
                    !vm.charge.isDirectPay
                ) {
                    vm.charge.isRaiseCharge = true;
                }
            }
        }

        function onPayFeeChanged() {
            vm.keepCheckedIfOnlyOneChecked('isPayFee');
            vm.uncheckMutuallyExclusive('isPayFee');
        }

        function onRaiseChargeChanged() {
            vm.keepCheckedIfOnlyOneChecked('isRaiseCharge');
            vm.uncheckMutuallyExclusive('isPayFee');
        }

        function onEstimateChanged() {
            vm.keepCheckedIfOnlyOneChecked('isEstimate');
            vm.uncheckMutuallyExclusive('isEstimate');
        }

        function onDirectPayChange() {
            if (vm.charge.isDirectPay) {
                vm.charge.isPayFee = false;
                vm.charge.isRaiseCharge = false;
                vm.charge.isEstimate = false;
            } else {
                vm.charge.isRaiseCharge = true;
            }
        }
       
        function keepCheckedIfOnlyOneChecked(checkbox) {
            var otherCheckboxes = _.without(allCheckboxes, checkbox);
            var allUnchecked = _.all(otherCheckboxes, function (checkboxName) {
                return !vm.charge[checkboxName];
            });

            if (allUnchecked) {
                vm.charge[checkbox] = true;
                return;
            }
        }
        
        function uncheckMutuallyExclusive(clickedCheckbox) {
            var uncheckOther = _.without(mutuallyExclusiveCheckboxes, clickedCheckbox)[0];
            if (
                vm.charge[clickedCheckbox] &&
                !vm.charge.isRaiseCharge
            ) {
                vm.charge[uncheckOther] = false;
            }
        }

        function isChargeTypeEmpty() {
            return !(vm.charge.chargeType && vm.charge.chargeType.key);
        }

        function isCheckboxDisabled() {
            return !vm.canEdit || isChargeTypeEmpty() || !!vm.charge.isDirectPay;
        }

        function isDirectPayDisabled() {
            return !vm.canEdit || isChargeTypeEmpty();
        }
    }
});