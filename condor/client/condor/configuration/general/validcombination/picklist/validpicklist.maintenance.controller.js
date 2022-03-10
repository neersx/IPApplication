angular.module('inprotech.configuration.general.validcombination')
    .controller('validPicklistMaintenanceController', function ($scope, states, validPicklistService) {
        'use strict';

        var vm = this;

        vm.init = init;
        vm.onPicklistSelectionChanged = onPicklistSelectionChanged;
        vm.init();

        function init() {
            if ($scope.state === states.adding) {
                if ($scope.model.validCombinationKeys) {
                    var keys = $scope.model.validCombinationKeys;
                    $scope.model.jurisdictions = [keys.jurisdictionModel];
                    if (keys.caseTypeModel) {
                        $scope.model.caseType = keys.caseTypeModel;
                        $scope.model.caseType.key = 0;
                    }
                    if (keys.propertyTypeModel && $scope.entityType !== 'propertyType') {
                        validPicklistService.getPropertyType(keys).then(function (propertyType) {
                            $scope.model.propertyType = propertyType.data;
                        })
                    }
                    if (keys.caseCategoryModel && $scope.entityType !== 'category' && keys.caseCategoryModel.code !== null) {
                        validPicklistService.getCaseCategory(keys).then(function (caseCategory) {
                            $scope.model.caseCategory = caseCategory.data;
                        })
                    }
                }
            }
        }        

        function onPicklistSelectionChanged(validDescription) {
            var picklist = $scope.model[$scope.entityType]
            if (!validDescription.$dirty && picklist) {
                $scope.model.validDescription = picklist.value;
            }
        }
    });