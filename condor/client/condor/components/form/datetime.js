angular.module('inprotech.components.form')
    .component('ipDateTime', {
        template: '<span><span data-ng-if="vm.useDefault" class="nobr" data-ng-show="vm.model">{{ vm.model | date:"medium" }}</span>' + '<span data-ng-if="!vm.useDefault" class="nobr" data-ng-show="vm.model">{{ vm.model | date:vm.format }} {{ vm.model | date:"mediumTime" }}</span></span>',
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
