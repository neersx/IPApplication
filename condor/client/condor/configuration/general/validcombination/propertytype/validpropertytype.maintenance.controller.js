angular.module('inprotech.configuration.general.validcombination')
    .controller('validPropertyTypeMaintenanceController', function($scope) {
        'use strict';

        var ctrl = this;
        ctrl.onOffsetChange = onOffsetChange;
        ctrl.clearAnnuityOptions = clearAnnuityOptions;

        //This function validates the max field for ip-text-type. By default ip-text-field only works on text type.
        function onOffsetChange() {
            if ($scope.model.offset && $scope.model.offset > 999999999) {
                $scope.maintenance.annuityOffset.$setValidity('notSupportedValue', false);
            } else {
                $scope.maintenance.annuityOffset.$setValidity('notSupportedValue', true);
            }

            if ($scope.model.cycleOffset && $scope.model.cycleOffset > 99) {
                $scope.maintenance.annuityCycleOffset.$setValidity('notSupportedValue', false);
            } else {
                $scope.maintenance.annuityCycleOffset.$setValidity('notSupportedValue', true);
            }
        }

        function clearAnnuityOptions() {
            $scope.model.offset = null;
            $scope.model.cycleOffset = null;
        }
    });