angular.module('inprotech.configuration.general.validcombination')
    .controller('actionMaintenanceController', function ($rootScope, modalService) {
        'use strict';

        var vm = this;

        vm.$onInit = onInit;

        function onInit() {

            vm.entity.isValid = formValid;
            vm.launchActionOrder = launchActionOrder;

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
                if (!angular.equals(vm.searchCriteria.action, {}) && vm.searchCriteria.action) {
                    vm.entity.action = vm.searchCriteria.action;
                    vm.entity.prepopulated = true;
                    if (vm.entity.action.value) {
                        vm.entity.validDescription = vm.entity.action.value;
                    }
                }
            }
        }

        function formValid() {
            return jurisdictionValid() && propertyTypeValid() && caseTypeValid() && actionValid() && validDescriptionValid();
        }

        function propertyTypeValid() {
            return vm.maintenance.propertyType && (vm.maintenance.propertyType.$dirty || vm.entity.propertyType) && vm.maintenance.propertyType.$valid;
        }

        function caseTypeValid() {
            return vm.maintenance.caseType && (vm.maintenance.caseType.$dirty || vm.entity.caseType) && vm.maintenance.caseType.$valid;
        }

        function jurisdictionValid() {
            return vm.maintenance.jurisdiction && (vm.maintenance.jurisdiction.$dirty || vm.entity.jurisdictions) && vm.maintenance.jurisdiction.$valid;
        }

        function actionValid() {
            return vm.maintenance.action && (vm.maintenance.action.$dirty || vm.entity.action) && vm.maintenance.action.$valid;
        }

        function validDescriptionValid() {
            return (vm.maintenance.validDescription.$dirty || vm.entity.validDescription) && vm.maintenance.validDescription.$valid;
        }

        function launchActionOrder() {
            var items = allItems();
            var dataItem = _.first(items);
            modalService.openModal({
                launchSrc: 'maintenance',
                id: 'ActionOrder',
                dataItem: dataItem,
                allItems: items,
                action: vm.entity.action,
                controllerAs: 'ctrl'
            });
        }

        function allItems() {
            var items = [];
            _.each(vm.entity.jurisdictions, function (jurisdiction) {
                items.push({
                    jurisdiction: jurisdiction,
                    propertyType: vm.entity.propertyType,
                    caseType: vm.entity.caseType
                });
            });
            return items;
        }

    });