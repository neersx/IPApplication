angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlDisplayConditions', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/display-conditions.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (ExtObjFactory, workflowsEventControlService) {
        'use strict';

        var vm = this;
        var viewData;
        var extObjFactory = new ExtObjFactory().useDefaults();
        var state = extObjFactory.createContext();

        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            vm.canEdit = viewData.canEdit;
            vm.formData = state.attach(viewData);
            vm.fieldClasses = fieldClasses;
            vm.validate = validate;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;
            vm.topic.hasError = hasError;
            vm.topic.discard = discard;
            vm.topic.afterSave = afterSave;
            vm.eventPicklistScope = workflowsEventControlService.initEventPicklistScope({
                criteriaId: viewData.criteriaId,
                filterByCriteria: true
            });
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                displayEvent: viewData.parent.displayEvent,
                hideEvent: viewData.parent.hideEvent,
                dimEvent: viewData.parent.dimEvent
            } : {};

            vm.isInherited = isInherited;

            vm.topic.initialised = true;
        }

        function fieldClasses(field) {
            return '{edited: vm.formData.isDirty(\'' + field + '\')}';
        }

        function isDirty() {
            return state.isDirty();
        }

        function hasError() {
            return vm.form.$invalid && vm.form.$dirty;
        }

        function discard() {
            vm.form.$reset();
            state.restore();
        }

        function isInherited() {
            return (
                angular.equals(vm.formData.displayEvent, vm.parentData.displayEvent) && angular.equals(vm.formData.hideEvent, vm.parentData.hideEvent) &&
                angular.equals(vm.formData.dimEvent, vm.parentData.dimEvent));
        }

        function getFormData() {
            return {
                displayEventNo: vm.formData.displayEvent ? vm.formData.displayEvent.key : null,
                hideEventNo: vm.formData.hideEvent ? vm.formData.hideEvent.key : null,
                dimEventNo: vm.formData.dimEvent ? vm.formData.dimEvent.key : null
            };
        }

        function afterSave() {
            state.save();
        }

        function validate(propertyName) {
            var data = getFormData();
            var errorKey = 'entrycontrol.displayConditions.invalidcombination';

            if (!data[propertyName]) {
                vm.form[propertyName].$setValidity(errorKey, null);
            }
            var total = _.filter(_.values(data), function (val) {
                return val;
            });
            if (_.uniq(total).length === total.length) {
                _.each(_.keys(data), function (key) {
                    vm.form[key].$setValidity(errorKey, null);
                });
            } else if (_.filter(_.values(data), function (val) {
                return data[propertyName] === val;
            }).length > 1) {
                vm.form[propertyName].$setValidity(errorKey, false);
            }
        }
        
    }
});
