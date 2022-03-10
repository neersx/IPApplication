angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlReport', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/report.html',
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

            vm.report = viewData.report;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? { report: viewData.parent.report } : {};
            vm.canEdit = viewData.canEdit;

            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function getFormData() {
            return {
                report: vm.report
            };
        }
    }
});
