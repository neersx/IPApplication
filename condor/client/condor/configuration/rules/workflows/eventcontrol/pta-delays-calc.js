angular.module('inprotech.configuration.rules.workflows')
    .component('ipWorkflowsEventControlPtaDelaysCalc', {
        templateUrl: 'condor/configuration/rules/workflows/eventcontrol/pta-delays-calc.html',
        bindings: {
            topic: '<'
        },
        controllerAs: 'vm',
        controller: function () {
            'use strict';

            var vm = this;
            var viewData;
            vm.$onInit = onInit;

            function onInit() {
                viewData = vm.topic.params.viewData;

                vm.ptaDelay = viewData.ptaDelay;
                vm.parentData = (viewData.isInherited === true && viewData.parent) ? { ptaDelay: viewData.parent.ptaDelay } : {};
                vm.canEdit = viewData.canEdit;

                vm.topic.isDirty = isDirty;
                vm.topic.getFormData = getFormData;
            }

            function isDirty() {
                return vm.form.$dirty;
            }

            function getFormData() {
                return {
                    PtaDelaySelection: vm.ptaDelay
                };
            }
        }
    });
