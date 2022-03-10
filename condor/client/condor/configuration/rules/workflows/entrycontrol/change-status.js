angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlChangeStatus', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/change-status.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (ExtObjFactory, workflowStatusService, notificationService, states, modalService, statusService) {
        'use strict';
        var vm = this;
        var originalRenewalStatus;
        var originalCaseStatus;
        var extObjFactory;
        var state;
        var service;
        var viewData;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            originalRenewalStatus = viewData.changeRenewalStatus;
            originalCaseStatus = viewData.changeCaseStatus;

            vm.fieldClasses = fieldClasses;
            vm.canEdit = viewData.canEdit;
            vm.topic.hasError = hasError;
            vm.topic.isDirty = isDirty;
            vm.topic.discard = discard;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.afterSave = afterSave;

            extObjFactory = new ExtObjFactory().useDefaults();
            state = extObjFactory.createContext();
            service = workflowStatusService(viewData.characteristics);

            vm.caseStatusScope = {
                validCombination: service.validCombination,
                filterByCriteria: true,
                extendQuery: extendForCaseStatus,
                canAddValidCombinations: viewData.canAddValidCombinations,
                add: add,
                type: 'case'
            };
            vm.renewalStatusScope = {
                validCombination: service.validCombination,
                filterByCriteria: true,
                extendQuery: extendForRenewalStatus,
                canAddValidCombinations: viewData.canAddValidCombinations,
                add: add,
                type: 'renewal'
            };
            vm.formData = state.attach(viewData);
            vm.changedStatus = changedStatus;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                changeCaseStatus: viewData.parent.changeCaseStatus,
                changeRenewalStatus: viewData.parent.changeRenewalStatus
            } : {};

            vm.topic.initialised = true;
        }

        function getTopicFormData() {
            return {
                caseStatusCodeId: vm.formData.changeCaseStatus ? vm.formData.changeCaseStatus.key : null,
                renewalStatusId: vm.formData.changeRenewalStatus ? vm.formData.changeRenewalStatus.key : null
            };
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

        function discard() {
            vm.form.$reset();
            state.restore();
        }

        function afterSave() {
            state.save();
        }

        function extendForCaseStatus(query) {
            if (!vm.caseStatusScope.picklistSearch) {
                if (_.isEmpty(query.search) || !vm.caseStatusScope.canAddValidCombinations) {
                    return service.caseStatusQuery(query);
                } else {
                    return service.allCaseStatusQuery(query);
                }
            }
            if (vm.caseStatusScope.filterByCriteria) {
                return service.caseStatusQuery(query);
            } else {
                return service.allCaseStatusQuery(query);
            }
        }

        function extendForRenewalStatus(query) {
            if (!vm.renewalStatusScope.picklistSearch) {
                if (_.isEmpty(query.search) || !vm.renewalStatusScope.canAddValidCombinations) {
                    return service.renewalStatusQuery(query);
                } else {
                    return service.allRenewalStatusQuery(query);
                }
            }
            if (vm.renewalStatusScope.filterByCriteria) {
                return service.renewalStatusQuery(query);
            } else {
                return service.allRenewalStatusQuery(query);
            }
        }

        function changedStatus(selectedStatus) {
            if (selectedStatus && service.validCombination) {
                service.isStatusValid(selectedStatus.key, selectedStatus.type === 'Renewal').then(function (response) {
                    if (response.isValid === false) {
                        notificationService.confirm({
                            title: 'modal.invalidStatus.title',
                            messages: ['modal.invalidStatus.message', 'modal.invalidStatus.proceed'],
                            continue: 'Proceed',
                            cancel: 'Cancel'
                        }).then(function () {
                            service.addValidStatus(selectedStatus, viewData.characteristics, response.isDefaultCountry);
                        }, function () {
                            if (selectedStatus.type === 'Renewal') {
                                vm.formData.changeRenewalStatus = originalRenewalStatus;
                            } else {
                                vm.formData.changeCaseStatus = originalCaseStatus;
                            }
                        });
                    }
                });
            }
        }

        function add(picklist) {
            var entity = {
                statusType: picklist.externalScope.type,
                statusSummary: 'pending',
                state: states.adding
            };
            statusService.supportData().then(function (data) {
                openStatusMaintenance(entity, data, picklist);
            });
        }

        function openStatusMaintenance(entity, supportData, picklist) {
            modalService.openModal({
                id: 'StatusMaintenance',
                entity: entity,
                supportData: supportData,
                controllerAs: 'vm'
            }).then(function () {
                notificationService.success();
                var key = _.last(statusService.savedStatusIds);
                statusService.get(key).then(function (data) {
                    var item = {
                        code: data.id,
                        value: data.name,
                        type: data.statusType.charAt(0).toUpperCase() + data.statusType.slice(1),
                        key: data.id,
                        id: data.id
                    };
                    if (picklist.externalScope.type === data.statusType) {
                        picklist.gridOptions.highlightAfterEditing(item);
                    }
                });
            });
        }        
    }
});