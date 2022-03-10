angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleDefinitionTopic', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-definition.html',
        bindings: {
            topic: '<'
        },
        controllerAs: 'vm',
        controller: function (dataSourceMap, knownValues) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                _.extend(vm, vm.topic.params.viewData);
                _.extend(vm, {
                    continuousRecurrence: knownValues.scheduleType.continuous,
                    hideDetailsLabel: vm.topic.params.viewData.schedule.dataSource === 'UsptoPrivatePair'
                });

                vm.template = dataSourceMap.partial(vm.schedule.dataSource, 'list');
            }
        }
    });