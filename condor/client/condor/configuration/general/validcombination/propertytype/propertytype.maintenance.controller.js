angular.module('inprotech.configuration.general.validcombination')
    .controller('propertytypeMaintenanceController', function () {
        'use strict';

        var vm = this;

        vm.$onInit = onInit;

        function onInit() {

            populateSearchCriteria();
        }

        function populateSearchCriteria() {
            if (vm.entity.state === 'adding') {
                if (vm.searchCriteria.jurisdictions) {
                    if (vm.searchCriteria.jurisdictions.length > 0) {
                        vm.entity.jurisdictions = vm.searchCriteria.jurisdictions;
                        vm.entity.prepopulated = true;
                    }
                }
                if (!angular.equals(vm.searchCriteria.propertyType, {}) && vm.searchCriteria.propertyType) {
                    vm.entity.propertyType = vm.searchCriteria.propertyType;
                    vm.entity.validDescription = vm.entity.propertyType.value;
                    vm.entity.prepopulated = true;
                }
            }
        }
    });