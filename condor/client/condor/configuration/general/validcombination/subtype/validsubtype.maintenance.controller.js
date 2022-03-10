angular.module('inprotech.configuration.general.validcombination')
    .controller('validSubTypeMaintenanceController', function ($scope, selectedCaseType, validCombinationConfig, validCombinationService) {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.onCaseCategorySelectionChanged = onCaseCategorySelectionChanged;
            vm.disableCategoryPicklist = disableCategoryPicklist;
            vm.onCaseTypeSelectionChanged = onCaseTypeSelectionChanged;
            vm.onSubTypeSelectionChanged = onSubTypeSelectionChanged;

            if ($scope.src && $scope.src === 'validcombination') {
                populateSearchCriteria();
            }

            vm.picklistCriteria = {
                extendQuery: function (query) {
                    if (!disableCategoryPicklist()) {
                        var extended = angular.extend({}, query, {
                            caseType: $scope.model.caseType.code,
                            latency: 888
                        });
                        return extended;
                    }
                }
            };
        }

        function onCaseTypeSelectionChanged() {
            selectedCaseType.set($scope.model.caseType);
            if (picklistHasValue($scope.model.caseType) && picklistHasValue($scope.model.caseCategory)) {
                validCombinationService.validateCategory($scope.model.caseType.code, $scope.model.caseCategory.code, validCombinationConfig.searchType.category).then(function (result) {
                    if (result.isValid) {
                        $scope.maintenance.caseCategory.$setValidity('invalidcombination', true);
                        if ($scope.model.caseCategory.code === result.key) {
                            $scope.model.caseCategory.value = result.value;
                        }
                    } else {
                        $scope.maintenance.caseCategory.$setValidity('invalidcombination', false);
                    }
                });
            }
        }        

        function populateSearchCriteria() {
            if ($scope.state === 'adding') {
                if (!angular.equals($scope.searchCriteria.caseType, {}) && $scope.searchCriteria.caseType) {
                    $scope.model.caseType = $scope.searchCriteria.caseType;
                    $scope.model.prepopulated = true;
                }
                if ($scope.searchCriteria.jurisdictions) {
                    if ($scope.searchCriteria.jurisdictions.length > 0) {
                        $scope.model.jurisdictions = $scope.searchCriteria.jurisdictions;
                        $scope.model.prepopulated = true;
                    }
                }
                if (!angular.equals($scope.searchCriteria.propertyType, {}) && $scope.searchCriteria.propertyType) {
                    $scope.model.propertyType = $scope.searchCriteria.propertyType;
                    $scope.model.prepopulated = true;
                }
                if (!angular.equals($scope.searchCriteria.caseCategory, {}) && $scope.searchCriteria.caseCategory) {
                    $scope.model.caseCategory = $scope.searchCriteria.caseCategory;
                    onCaseCategorySelectionChanged();
                    $scope.model.prepopulated = true;
                }
                if (!angular.equals($scope.searchCriteria.subType, {}) && $scope.searchCriteria.subType) {
                    $scope.model.subType = $scope.searchCriteria.subType;
                    $scope.model.validDescription = $scope.model.subType.value;
                    $scope.model.prepopulated = true;
                }
            }
            selectedCaseType.set($scope.model.caseType);
        }

        function onCaseCategorySelectionChanged() {
            if (angular.isDefined($scope.maintenance) && $scope.maintenance.caseCategory) {
                $scope.maintenance.caseCategory.$setValidity('invalidcombination', true);
            }
        }

        function onSubTypeSelectionChanged(validDescription) {
            if (!validDescription.$dirty && angular.isDefined($scope.model.subType) && $scope.model.subType !== null) {
                $scope.model.validDescription = $scope.model.subType.value;
            }
        }        

        function disableCategoryPicklist() {
            var disableCategory = !picklistHasValue($scope.model.caseType) || hasCaseTypeErrors();
            if (disableCategory && picklistHasValue($scope.model.caseCategory)) {
                $scope.model.caseCategory = null;
                $scope.maintenance.caseCategory.$resetErrors();
            }
            return disableCategory;
        }

        function picklistHasValue(picklist) {
            return angular.isDefined(picklist) && picklist !== null;
        }

        function hasCaseTypeErrors() {
            return angular.isDefined($scope.maintenance.caseType) && $scope.maintenance.caseType.$invalid;
        }

    });