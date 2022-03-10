angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlStandingInstruction', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/standing-instruction.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (workflowsEventControlService) {
        'use strict';

        var vm = this;
        var viewData;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            vm.parentData = (viewData.isInherited === true) ? viewData.parent.standingInstruction : {}

            _.extend(vm.topic, {
                isDirty: isDirty,
                hasError: hasError,
                getFormData: getFormData
            });

            _.extend(vm, {
                formData: viewData.standingInstruction,
                characteristicsOptions: viewData.standingInstruction.characteristicsOptions,
                instructions: viewData.standingInstruction.instructions,
                canEdit: viewData.canEdit,
                displayInstructions: displayInstructions,
                onInstructionTypeChange: onInstructionTypeChange,
                isCharacteristicRequired: isCharacteristicRequired,
                isCharacteristicDisabled: isCharacteristicDisabled,
                onCharacteristicChange: onCharacteristicChange
            });

            vm.isInherited = isInherited;
        }

        function isInherited() {
            return angular.equals(vm.formData, vm.parentData);
        }

        function displayInstructions() {
            if (!vm.instructions) {
                return '';
            }

            return vm.instructions.join('; ');
        }

        function onInstructionTypeChange() {
            vm.formData.requiredCharacteristic = null;
            vm.instructions = null;

            if (vm.formData.instructionType) {
                workflowsEventControlService.getCharacteristicOptions(vm.formData.instructionType.code).then(function (data) {
                    vm.characteristicsOptions = data;
                });
            }
        }

        function isCharacteristicRequired() {
            return vm.formData.instructionType != null;
        }

        function isCharacteristicDisabled() {
            return !vm.canEdit || vm.formData.instructionType == null;
        }

        function onCharacteristicChange() {
            if (vm.formData.requiredCharacteristic) {
                workflowsEventControlService.getUsedInInstructions(vm.formData.requiredCharacteristic).then(function (data) {
                    vm.instructions = data;
                });
            }
        }

        function isDirty() {
            return vm.form && vm.form.$dirty;
        }

        function hasError() {
            return !customValidate() || !!(vm.form && vm.form.$invalid);
        }

        function getFormData() {
            return {
                instructionType: vm.formData.instructionType ? vm.formData.instructionType.code : null,
                characteristic: vm.formData.requiredCharacteristic
            };
        }

        function customValidate() {
            var valid = true;

            if (vm.form.instructionType) {
                valid = !(viewData.dueDateDependsOnStandingInstruction && (isNaN(vm.formData.requiredCharacteristic) || vm.formData.requiredCharacteristic === null));
                vm.form.instructionType.$setValidity('eventcontrol.standingInstruction.dueDateCalcWarning', valid);
            }

            return valid;
        }
    }
});
