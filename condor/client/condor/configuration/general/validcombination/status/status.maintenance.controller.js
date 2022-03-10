angular.module('inprotech.configuration.general.validcombination')
    .controller('statusMaintenanceController', function () {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.entity.isValid = formValid;

            populateSearchCriteria();
        }

        function populateSearchCriteria() {
            if (vm.entity.state === 'adding') {
                if (!angular.equals(vm.searchCriteria.caseType, {}) && vm.searchCriteria.caseType) {
                    vm.entity.caseType = vm.searchCriteria.caseType;
                    vm.entity.prepopulated = true;
                }
                if (vm.searchCriteria.jurisdictions) {
                    if (vm.searchCriteria.jurisdictions.length > 0) {
                        vm.entity.jurisdictions = vm.searchCriteria.jurisdictions;
                        vm.entity.prepopulated = true;
                    }
                }
                if (!angular.equals(vm.searchCriteria.propertyType, {}) && vm.searchCriteria.caseType) {
                    vm.entity.propertyType = vm.searchCriteria.propertyType;
                    vm.entity.prepopulated = true;
                }
                if (!angular.equals(vm.searchCriteria.status, {}) && vm.searchCriteria.status) {
                    vm.entity.status = vm.searchCriteria.status;
                    vm.entity.prepopulated = true;
                }
            }
        }

        function formValid() {
            return jurisdictionValid() && propertyTypeValid() && caseTypeValid() && statusValid();
        }

        function propertyTypeValid() {
            return vm.maintenance.propertyType && (vm.maintenance.propertyType.$dirty || vm.entity.propertyType) && vm.maintenance.propertyType.$valid;
        }

        function jurisdictionValid() {
            return vm.maintenance.jurisdiction && (vm.maintenance.jurisdiction.$dirty || vm.entity.jurisdictions) && vm.maintenance.jurisdiction.$valid;
        }

        function caseTypeValid() {
            return vm.maintenance.caseType && (vm.maintenance.caseType.$dirty || vm.entity.caseType) && vm.maintenance.caseType.$valid;
        }

        function statusValid() {
            return vm.maintenance.status && (vm.maintenance.status.$dirty || vm.entity.status) && vm.maintenance.status.$valid;
        }
    });