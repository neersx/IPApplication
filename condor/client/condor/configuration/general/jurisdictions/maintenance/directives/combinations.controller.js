angular.module('inprotech.configuration.general.jurisdictions')
    .controller('ValidCombinationsController', function ($scope, $state, kendoGridBuilder, jurisdictionCombinationsService) {
        'use strict';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.parentId = $scope.parentId;
            vm.parentName = $scope.parentName;
            vm.hasValidCombinations = false;
            vm.displayLink = false;

            generateLink();
        }

        function generateLink() {
            jurisdictionCombinationsService.hasCombinations(vm.parentId).then(function (response) {
                vm.hasValidCombinations = response.hasCombinations;
                vm.displayLink = response.canAccessValidCombinations;
            });
        }


    });
