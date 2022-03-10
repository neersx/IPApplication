angular.module('inprotech.configuration.general.validcombination')
    .controller('checklistMaintenanceController', function () {
        'use strict';

        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            vm.onChecklistSelectionChanged = onChecklistSelectionChanged;
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
                if (!angular.equals(vm.searchCriteria.propertyType, {}) && vm.searchCriteria.propertyType) {
                    vm.entity.propertyType = vm.searchCriteria.propertyType;
                    vm.entity.prepopulated = true;
                }
                if (!angular.equals(vm.searchCriteria.checklist, {}) && vm.searchCriteria.checklist) {
                    vm.entity.checklist = vm.searchCriteria.checklist;
                    onChecklistSelectionChanged(false);
                    vm.entity.prepopulated = true;
                }
            }
        }

        function onChecklistSelectionChanged(validDescription) {
            vm.entity.checklistDirty = true;
            if (!validDescription.$dirty && angular.isDefined(vm.entity.checklist)) {
                vm.entity.validDescription = vm.entity.checklist.value;
            }
        }

        function formValid() {
            return propertyTypeValid() && jurisdictionValid() && caseTypeValid() && checkListValid() && validDescriptionValid();
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

        function checkListValid() {
            return (vm.maintenance.checklist.$dirty || vm.entity.checklist) && vm.maintenance.checklist.$valid;
        }

        function validDescriptionValid() {
            return (vm.maintenance.validDescription.$dirty || vm.entity.validDescription) && vm.maintenance.validDescription.$valid;
        }
    });