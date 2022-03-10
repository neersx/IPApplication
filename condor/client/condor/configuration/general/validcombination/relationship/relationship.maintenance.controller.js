angular.module('inprotech.configuration.general.validcombination')
    .controller('relationshipMaintenanceController', function () {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.entity.isValid = formValid;

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
                    vm.entity.prepopulated = true;
                }
                if (!angular.equals(vm.searchCriteria.relationship, {}) && vm.searchCriteria.relationship) {
                    vm.entity.relationship = vm.searchCriteria.relationship;
                    vm.entity.prepopulated = true;
                }
            }
        }

        function formValid() {
            return jurisdictionValid() && propertyTypeValid() && relationshipValid();
        }

        function propertyTypeValid() {
            return vm.maintenance.propertyType && (vm.maintenance.propertyType.$dirty || vm.entity.propertyType) && vm.maintenance.propertyType.$valid;
        }

        function jurisdictionValid() {
            return vm.maintenance.jurisdiction && (vm.maintenance.jurisdiction.$dirty || vm.entity.jurisdictions) && vm.maintenance.jurisdiction.$valid;
        }

        function relationshipValid() {
            return vm.maintenance.relationship && (vm.maintenance.relationship.$dirty || vm.entity.relationship) && vm.maintenance.relationship.$valid;
        }
    });