angular.module('inprotech.configuration.general.validcombination')
    .controller('basisMaintenanceController', function () {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {

            vm.entity.isValid = formValid;
            vm.categoryPlaceholder = 'validcombinations.selectCaseTypeForCategory';
        }

        function formValid() {
            return jurisdictionValid() && propertyTypeValid() && basisValid() && caseCategoryValid() && validDescriptionValid();
        }

        function propertyTypeValid() {
            return vm.maintenance.propertyType && (vm.maintenance.propertyType.$dirty || vm.entity.propertyType) && vm.maintenance.propertyType.$valid;
        }

        function jurisdictionValid() {
            return vm.maintenance.jurisdiction && (vm.maintenance.jurisdiction.$dirty || vm.entity.jurisdictions) && vm.maintenance.jurisdiction.$valid;
        }

        function basisValid() {
            return vm.maintenance.basis && (vm.maintenance.basis.$dirty || vm.entity.basis) && vm.maintenance.basis.$valid;
        }

        function caseCategoryValid() {
            return vm.maintenance.caseCategory && vm.maintenance.caseCategory.$valid;
        }

        function validDescriptionValid() {
            return (vm.maintenance.validDescription.$dirty || vm.entity.validDescription) && vm.maintenance.validDescription.$valid;
        }
    });