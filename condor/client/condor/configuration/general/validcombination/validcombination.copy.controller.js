angular.module('inprotech.configuration.general.validcombination')
    .controller('CopyValidCombinationController', function () {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.selectAll = selectAll;
            vm.enableCopySave = enableCopySave;
            vm.selectAnyCharacteristic = selectAnyCharacteristic;

            vm.copyEntity.selectAll = true;
            vm.copyEntity.hasSameValue = hasSameValue;
            vm.copyEntity.picklistsDirty = picklistsDirty;
            vm.selectAll();
        }

        function picklistsDirty() {
            return vm.fromJurisdictionDirty || vm.toJurisdictionDirty;
        }

        function selectAll() {
            var selectAllValue = vm.copyEntity.selectAll;
            vm.copyEntity.propertyType = selectAllValue;
            vm.copyEntity.category = selectAllValue;
            vm.copyEntity.action = selectAllValue;
            vm.copyEntity.basis = selectAllValue;
            vm.copyEntity.checklist = selectAllValue;
            vm.copyEntity.relationship = selectAllValue;
            vm.copyEntity.subType = selectAllValue;
            vm.copyEntity.status = selectAllValue;
        }

        function selectAnyCharacteristic(value) {
            if (!value) {
                vm.copyEntity.selectAll = false;
            }
        }

        function enableCopySave() {
            return vm.jurisdictions && vm.jurisdictions.$dirty && vm.jurisdictions.$valid;
        }

        function isUndefinedOrNull(value) {
            return angular.isUndefined(value) || value === null;
        }

        function hasSameValue() {
            var sameJurisdiction = _.find(vm.copyEntity.toJurisdictions, function (toJurisdiction) {
                return toJurisdiction.key === vm.copyEntity.fromJurisdiction.key;
            });
            return !isUndefinedOrNull(sameJurisdiction);
        }
    });