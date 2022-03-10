angular.module('inprotech.components')
    .component('ipInheritanceIcon', {
        bindings: {
            inheritanceLevel: '@'
        },
        templateUrl: 'condor/components/indicators/inheritanceIcon.html',
        controllerAs: 'vm',
        controller: function () {
            'use strict';

            var vm = this;
            var tooltipMap = {
                'Full': 'Inheritance.FullyInherited',
                'Partial': 'Inheritance.PartiallyInherited',
                'InheritedOrDerived': 'Inheritance.InheritedOrDerived'
            }

            vm.$onInit = onInit;

            function onInit() {

                vm.tooltip = vm.inheritanceLevel == null ? 'Inheritance.inherits' : tooltipMap[vm.inheritanceLevel];
            }
        }
    });