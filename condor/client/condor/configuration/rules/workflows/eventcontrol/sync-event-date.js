angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlSyncEventDate', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/sync-event-date.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (workflowsEventControlService) {
        'use strict';

        var vm = this;
        var viewData;
        var syncedEvent;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            syncedEvent = viewData.syncedEventSettings;

            _.extend(vm, {
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                canEdit: viewData.canEdit,
                caseOption: syncedEvent.caseOption,
                dateAdjustmentOptions: syncedEvent.dateAdjustmentOptions
            });

            vm.sameCase = isSameCase() ? {
                fromEvent: syncedEvent.fromEvent,
                dateAdjustment: syncedEvent.dateAdjustment
            } : {};

            vm.relatedCase = isRelatedCase() ? {
                fromEvent: syncedEvent.fromEvent,
                dateAdjustment: syncedEvent.dateAdjustment,
                fromRelationship: syncedEvent.fromRelationship,
                loadNumberType: syncedEvent.loadNumberType,
                useCycle: syncedEvent.useCycle
            } : {
                    useCycle: 'RelatedCaseEvent'
                };

            vm.showSameCaseOptions = isSameCase;
            vm.showRelatedCaseOptions = isRelatedCase;
            vm.topic.isDirty = isDirty;
            vm.topic.hasError = hasError;
            vm.topic.getFormData = getFormData;
            vm.topic.validate = validate;
            vm.getCurrentForm = getCurrentForm;

            vm.sameCaseEventPicklistScope = workflowsEventControlService.initEventPicklistScope({
                criteriaId: viewData.criteriaId,
                filterByCriteria: false
            });

            vm.relatedCaseEventPicklistScope = workflowsEventControlService.initEventPicklistScope({
                criteriaId: viewData.criteriaId,
                filterByCriteria: false
            });
            vm.isInherited = isInherited;

            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                caseOption: viewData.parent.syncedEventSettings.caseOption,
                sameCase: viewData.parent.syncedEventSettings.caseOption === 'SameCase' ? {
                    fromEvent: viewData.parent.syncedEventSettings.fromEvent,
                    dateAdjustment: viewData.parent.syncedEventSettings.dateAdjustment
                } : {},
                relatedCase: viewData.parent.syncedEventSettings.caseOption === 'RelatedCase' ? {
                    fromEvent: viewData.parent.syncedEventSettings.fromEvent,
                    dateAdjustment: viewData.parent.syncedEventSettings.dateAdjustment,
                    fromRelationship: viewData.parent.syncedEventSettings.fromRelationship,
                    loadNumberType: viewData.parent.syncedEventSettings.loadNumberType,
                    useCycle: viewData.parent.syncedEventSettings.useCycle
                } : {
                        useCycle: 'RelatedCaseEvent'
                    }
            } : {};
        }

        function isRelatedCase() {
            return vm.caseOption === 'RelatedCase';
        }

        function isSameCase() {
            return vm.caseOption === 'SameCase';
        }

        function isInherited() {
            return ((vm.caseOption === vm.parentData.caseOption) ?
                angular.equals(vm.sameCase, vm.parentData.sameCase) && angular.equals(vm.relatedCase, vm.parentData.relatedCase) : false);
        }

        function getCurrentForm() {
            if (isSameCase()) {
                return vm.form.sameCase;
            } else if (isRelatedCase()) {
                return vm.form.relatedCase;
            }
        }

        function hasError() {
            return getCurrentForm() && getCurrentForm().$invalid;
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function validate() {
            return getCurrentForm() == null ? true : getCurrentForm().$validate();
        }

        function getFormData() {
            var formData = {
                caseOption: vm.caseOption
            };

            if (isSameCase()) {
                _.extend(formData, {
                    fromEvent: vm.sameCase.fromEvent && vm.sameCase.fromEvent.key,
                    dateAdjustment: vm.sameCase.dateAdjustment
                });
            } else if (isRelatedCase()) {
                _.extend(formData, {
                    fromEvent: vm.relatedCase.fromEvent && vm.relatedCase.fromEvent.key,
                    dateAdjustment: vm.relatedCase.dateAdjustment,
                    fromRelationship: vm.relatedCase.fromRelationship && vm.relatedCase.fromRelationship.key,
                    loadNumberType: vm.relatedCase.loadNumberType && vm.relatedCase.loadNumberType.key,
                    useCycle: vm.relatedCase.useCycle
                });
            }

            return formData;
        }
    }
});
