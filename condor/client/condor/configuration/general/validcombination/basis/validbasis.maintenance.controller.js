angular.module('inprotech.configuration.general.validcombination')
    .controller('validBasisMaintenanceController', function($scope, selectedCaseType, validCombinationConfig, validCombinationService) {
        'use strict';

        var ctrl = this;
        ctrl.onCaseCategorySelectionChanged = onCaseCategorySelectionChanged;
        ctrl.disableCategoryPicklist = disableCategoryPicklist;
        ctrl.onCaseTypeSelectionChanged = onCaseTypeSelectionChanged;
        ctrl.onBasisSelectionChanged = onBasisSelectionChanged;

        function onCaseTypeSelectionChanged() {
            selectedCaseType.set($scope.model.caseType);
            if (picklistHasValue($scope.model.caseType) && picklistHasValue($scope.model.caseCategory)) {
                validCombinationService.validateCategory($scope.model.caseType.code, $scope.model.caseCategory.code, validCombinationConfig.searchType.category).then(function(result) {
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

        if ($scope.src && $scope.src === 'validcombination') {
            populateSearchCriteria();
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
                if (!angular.equals($scope.searchCriteria.basis, {}) && $scope.searchCriteria.basis) {
                    $scope.model.basis = $scope.searchCriteria.basis;
                    $scope.model.validDescription = $scope.model.basis.value;
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

        function onBasisSelectionChanged(validDescription) {
            if (!validDescription.$dirty && angular.isDefined($scope.model.basis) && $scope.model.basis !== null) {
                $scope.model.validDescription = $scope.model.basis.value;
            }
        }

        ctrl.picklistCriteria = {
            extendQuery: function(query) {
                if (!disableCategoryPicklist()) {
                    var extended = angular.extend({}, query, {
                        caseType: $scope.model.caseType.code,
                        latency: 888
                    });
                    return extended;
                }
            }
        };

        function disableCategoryPicklist() {
            if ($scope.model) {
                var disableCategory = !picklistHasValue($scope.model.caseType) || hasCaseTypeErrors();
                if (disableCategory && picklistHasValue($scope.model.caseCategory)) {
                    $scope.model.caseCategory = null;
                    $scope.maintenance.caseCategory.$resetErrors();
                }
                return disableCategory;
            }
            return true;
        }

        function picklistHasValue(picklist) {
            return angular.isDefined(picklist) && picklist !== null;
        }

        function hasCaseTypeErrors() {
            return angular.isDefined($scope.maintenance.caseType) && $scope.maintenance.caseType.$invalid;
        }

    });