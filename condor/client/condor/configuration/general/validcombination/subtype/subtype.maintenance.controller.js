angular.module('inprotech.configuration.general.validcombination')
    .controller('subtypeMaintenanceController', function () {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.entity.isValid = formValid;
            vm.categoryPlaceholder = 'validcombinations.selectCaseTypeForCategory';
        }

        function formValid() {
            return caseTypeValid() && propertyTypeValid() && jurisdictionValid() && caseTypeValid() && caseCategoryValid() && subTypeValid() && validDescriptionValid();
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

        function caseCategoryValid() {
            return vm.maintenance.caseCategory && (vm.maintenance.caseCategory.$dirty || vm.entity.caseCategory) && vm.maintenance.caseCategory.$valid;
        }

        function subTypeValid() {
            return vm.maintenance.subType && (vm.maintenance.subType.$dirty || vm.entity.subType) && vm.maintenance.subType.$valid;
        }

        function validDescriptionValid() {
            return (vm.maintenance.validDescription.$dirty || vm.entity.validDescription) && vm.maintenance.validDescription.$valid;
        }


    });
