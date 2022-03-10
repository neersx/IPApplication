angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleCaseSource', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-case-source-component.html',
        bindings: {
            schedule: '<',
            maintenance: '='
        },
        controllerAs: 'vm',
        controller: function () {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                vm.savedQuerySelected = null;
                vm.runAsUserSelected = null;
                vm.onPicklistSelectionChanged = onPicklistSelectionChanged;
            }

            function onPicklistSelectionChanged(pk) {
                switch (pk) {
                    case 'savedQuerySelected':
                        vm.schedule.savedQueryId = vm.savedQuerySelected ? vm.savedQuerySelected.key : '';
                        vm.schedule.savedQueryName = vm.savedQuerySelected ? vm.savedQuerySelected.name : '';
                        break;
                    case 'runAsUserSelected':
                        vm.schedule.runAsUserId = vm.runAsUserSelected ? vm.runAsUserSelected.key : '';
                        vm.schedule.runAsUserName = vm.runAsUserSelected ? vm.runAsUserSelected.username : '';
                        break;
                }
            }
        }
    });