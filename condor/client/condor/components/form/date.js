angular.module('inprotech.components.form')
    .component('ipDate', {
        template: '<span><span data-ng-if="vm.useDefault" class="nobr" data-ng-show="vm.model">{{ vm.model | localeDate }}</span>' + '<span data-ng-if="!vm.useDefault" class="nobr" data-ng-show="vm.model">{{ vm.model | localeDate }}</span></span>',
        bindings: {
            model: '<'
        },
        controllerAs: 'vm',
        controller: function (dateService) {
            'use strict';

            var vm = this;

            vm.$onInit = onInit;

            function onInit() {
                vm.useDefault = dateService.useDefault();
                vm.format = dateService.dateFormat;
            }
        }
    });