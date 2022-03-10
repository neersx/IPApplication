angular.module('Inprotech.Integration.PtoAccess')
    .component('scheduleDescription', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-description.html',
        bindings: {
            model: '<'
        },
        controllerAs: 'vm',
        controller: function ($state, knownValues) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                vm.continuousRecurrence = knownValues.scheduleType.continuous;
                vm.details = details;
                vm.description = this.model.downloadDesc;
                if (vm.model.type != knownValues.scheduleType.continuous) {
                    vm.description += ' - ' + this.model.presetDesc + '.';
                } else {
                    vm.description += ' -';
                }
            }

            function details(id) {
                $state.go('classicPtoAccess.SchedulesDetail', {
                    id: id
                });
            }
        }
    });