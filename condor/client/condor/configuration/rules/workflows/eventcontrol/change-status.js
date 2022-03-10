angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlChangeStatus', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/change-status.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function (workflowStatusService, notificationService, states, modalService, statusService) {
        'use strict';

        var vm = this;
        var viewData;
        var service;

        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            service = workflowStatusService(viewData.characteristics);
            _.extend(vm.topic, {
                hasError: hasError,
                isDirty: isDirty,
                getFormData: getFormData
            });

            vm.canEdit = viewData.canEdit;
            vm.changeStatus = viewData.changeStatus;
            vm.changeRenewalStatus = viewData.changeRenewalStatus;
            vm.userDefinedStatus = viewData.userDefinedStatus;
            vm.enableRenewalStatus = viewData.isRenewalStatusSupported;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                changeStatus: viewData.parent.changeStatus,
                changeRenewalStatus: viewData.parent.changeRenewalStatus,
                userDefinedStatus: viewData.parent.userDefinedStatus
            } : {};

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
            vm.validStatusScope = {
                validCombination: service.validCombination,
                filterByCriteria: true,
                extendQuery: extendForValidStatus,
                canAddValidCombinations: viewData.canAddValidCombinations,
                add: add,
                type: 'case'
            }
            vm.changedStatus = changedStatus;
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty;
        }

        function getFormData() {
            return {
                changeStatusId: vm.changeStatus ? vm.changeStatus.key : null,
                changeRenewalStatusId: vm.changeRenewalStatus ? vm.changeRenewalStatus.key : null,
                userDefinedStatus: vm.userDefinedStatus
            }
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

        function extendForValidStatus(query) {
            if (!vm.validStatusScope.picklistSearch) {
                if (_.isEmpty(query.search) || !vm.validStatusScope.canAddValidCombinations) {
                    return service.validStatusQuery(query);
                } else {
                    return service.allValidStatusQuery(query);
                }
            }
            if (vm.validStatusScope.filterByCriteria) {
                return service.validStatusQuery(query);
            } else {
                return service.allValidStatusQuery(query);
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
                            if (vm.enableRenewalStatus) {
                                if (selectedStatus.type === 'Renewal') {
                                    vm.changeRenewalStatus = viewData.changeRenewalStatus;
                                } else {
                                    vm.changeStatus = viewData.changeStatus;
                                }
                            } else {
                                vm.changeStatus = viewData.changeStatus;
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