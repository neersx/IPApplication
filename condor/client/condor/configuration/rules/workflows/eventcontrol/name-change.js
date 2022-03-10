angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlNameChange', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/name-change.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function () {
        'use strict';

        var vm = this;
        var viewData;
        var translationPrefix;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;

            vm.formData = viewData.nameChangeSettings;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? viewData.parent.nameChangeSettings : {};
            vm.canEdit = viewData.canEdit;

            translationPrefix = 'workflows.eventcontrol.nameChange.';

            vm.shouldCopyFromNameTypeRequired = false;
            vm.shouldCopyFromNameTypeDisabled = false;
            vm.shouldMoveOldNameToNameTypeDisabled = false;
            vm.shouldDeleteCopyFromNameDisabled = false;

            _.extend(vm.topic, {
                hasError: hasError,
                isDirty: isDirty,
                validate: validate,
                getFormData: getFormData
            });

            vm.isInherited = isInherited;

            onLoad();
        }

        function isInherited() {
            return angular.equals(vm.formData, vm.parentData);
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
                changeNameTypeCode: vm.formData.changeNameType && vm.formData.changeNameType.code,
                copyFromNameTypeCode: vm.formData.copyFromNameType && vm.formData.copyFromNameType.code,
                moveOldNameToNameTypeCode: vm.formData.moveOldNameToNameType && vm.formData.moveOldNameToNameType.code,
                deleteCopyFromName: vm.formData.deleteCopyFromName
            };
        }

        vm.deleteFromTranslationKey = function () {
            return vm.formData.copyFromNameType && vm.formData.copyFromNameType.value ? translationPrefix + 'andDeleteNameDynamic' : translationPrefix + 'andDeleteName';
        };

        vm.moveNameTranslationKey = function () {
            return vm.formData.changeNameType && vm.formData.changeNameType.value ? translationPrefix + 'moveOriginalNameToDynamic' : translationPrefix + 'moveOriginalNameTo';
        };

        vm.isCopyFromNameTypeRequired = function () {
            return vm.shouldCopyFromNameTypeRequired;
        };

        vm.isCopyFromNameTypeDisabled = function () {
            if (vm.shouldCopyFromNameTypeDisabled) {
                vm.form.copyFromNameType.$dirty = false;
            }
            return vm.shouldCopyFromNameTypeDisabled;
        };

        vm.isDeleteCopyFromNameDisabled = function () {
            if (vm.shouldDeleteCopyFromNameDisabled) {
                vm.form.deleteCopyFromName.$dirty = false;
            }
            return vm.shouldDeleteCopyFromNameDisabled;
        };

        vm.isMoveOldNameToNameTypeDisabled = function () {
            if (vm.shouldMoveOldNameToNameTypeDisabled) {
                vm.form.moveOldNameToNameType.$dirty = false;
            }
            return vm.shouldMoveOldNameToNameTypeDisabled;
        };

        vm.onChangeOfChangeNameType = function () {
            if (isPicklistEmpty(vm.formData.changeNameType)) {
                vm.formData.copyFromNameType = null;
                vm.formData.moveOldNameToNameType = null;
                vm.shouldCopyFromNameTypeRequired = false;
                vm.shouldMoveOldNameToNameTypeDisabled = true;
                vm.shouldCopyFromNameTypeDisabled = true;
            } else {
                vm.shouldCopyFromNameTypeRequired = true;
                vm.shouldMoveOldNameToNameTypeDisabled = false;
                vm.shouldCopyFromNameTypeDisabled = false;
            }
            vm.onChangeOfCopyFromNameType();
        };

        vm.onChangeOfCopyFromNameType = function () {
            if (isPicklistEmpty(vm.formData.copyFromNameType)) {
                vm.formData.deleteCopyFromName = false;
                vm.shouldDeleteCopyFromNameDisabled = true;
            } else {
                vm.shouldDeleteCopyFromNameDisabled = false;
            }
        };

        function isPicklistEmpty(formDataField) {
            return formDataField == null || _.isNull(formDataField.key);
        }

        function resetEmpty() {
            if (isPicklistEmpty(vm.formData.changeNameType)) {
                vm.formData.changeNameType = null;
            }
            if (isPicklistEmpty(vm.formData.copyFromNameType)) {
                vm.formData.copyFromNameType = null;
            }
            if (isPicklistEmpty(vm.formData.moveOldNameToNameType)) {
                vm.formData.moveOldNameToNameType = null;
            }
        }

        function onLoad() {
            resetEmpty();
            vm.onChangeOfChangeNameType();
        }        
    }
});
