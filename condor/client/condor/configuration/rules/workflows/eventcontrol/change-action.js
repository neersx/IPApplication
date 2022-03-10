angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlChangeAction', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/change-action.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (workflowsEventControlService) {
        'use strict';

        var viewData;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;

            vm.changeAction = viewData.changeAction;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? viewData.parent.changeAction : {};
            vm.canEdit = viewData.canEdit;
            vm.relativeCycles = workflowsEventControlService.relativeCycles;
            vm.isCloseActionEmpty = isCloseActionEmpty;
            vm.isReletiveCycleDisabled = isReletiveCycleDisabled;
            vm.onCloseActionChange = onCloseActionChange;
            _.extend(vm.topic, {
                hasError: hasError,
                isDirty: isDirty,
                validate: validate,
                getFormData: getFormData
            });

            vm.isInherited = isInherited;
            onload();
        }

        function onCloseActionChange() {
            vm.form.relativeCycle.$setDirty();
            if (vm.isCloseActionEmpty()) {
                vm.changeAction.relativeCycle = null;
            } else {
                updateRelativeCycle(vm.changeAction.closeAction.cycles);
            }
        }

        function updateRelativeCycle(cycles) {
            if (cycles == 1) {
                vm.changeAction.relativeCycle = 3;
            } else {
                vm.changeAction.relativeCycle = 0;
            }
        }

        function isInherited() {
            return angular.equals(vm.changeAction, vm.parentData);
        }

        function isReletiveCycleDisabled() {
            return !vm.canEdit || vm.isCloseActionEmpty();
        }

        function isCloseActionEmpty() {
            return vm.changeAction.closeAction == null || vm.changeAction.closeAction.key == null;
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function validate() {
            return vm.form.$validate();
        }

        function getFormData() {
            return {
                //.key and .code store diffierent values for actions, opt for .key as backup value
                openActionId: vm.changeAction.openAction && (vm.changeAction.openAction.code || vm.changeAction.openAction.key),
                closeActionId: vm.changeAction.closeAction && (vm.changeAction.closeAction.code || vm.changeAction.closeAction.key),
                relativeCycle: vm.changeAction.relativeCycle
            }
        }

        function onload() {
            if (vm.isCloseActionEmpty()) {
                vm.changeAction.relativeCycle = null
            }
        }        
    }
});