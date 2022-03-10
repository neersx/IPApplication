angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlDefinition', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/definition.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (ExtObjFactory) {
        'use strict';
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.topic.initialised = true;
            init();
        }
        var extObjFactory = new ExtObjFactory().useDefaults();
        var state = extObjFactory.createContext();

        function init() {
            var viewData = vm.topic.params.viewData;

            if (!viewData.userInstruction) {
                viewData.userInstruction = '';
            }

            vm.formData = state.attach(viewData);
            vm.entryId = viewData.entryId;
            vm.canEdit = viewData.canEdit;
            vm.fieldClasses = fieldClasses;
            vm.topic.hasError = hasError;
            vm.topic.setError = setError;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getTopicFormData;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                description: viewData.parent.description,
                userInstruction: viewData.parent.userInstruction
            } : {};
        }

        function fieldClasses(field) {
            return '{edited: vm.formData.isDirty(\'' + field + '\')}';
        }

        function hasError() {
            return vm.form.$invalid && vm.form.$dirty;
        }

        function isDirty() {
            return state.isDirty();
        }

        function getTopicFormData() {
            var rawData = vm.formData.getRaw();
            return {
                description: rawData.description,
                userInstruction: rawData.userInstruction
            }
        }

        function setError(errors) {
            var descriptionError = _.findWhere(errors, {
                field: 'description'
            });

            if (descriptionError) {
                vm.formData.hasError("description", descriptionError.message);
            }
        }
    }
});
