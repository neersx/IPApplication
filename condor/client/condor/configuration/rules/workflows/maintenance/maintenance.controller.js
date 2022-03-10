angular.module('inprotech.configuration.rules.workflows').controller('WorkflowsMaintenanceController', function (viewData, notificationService, workflowsMaintenanceService, workflowInheritanceService, sharedService, $translate, $state, modalService, LastSearch, store, workflowsSearchService, $rootScope) {
    'use strict';
    var vm = this;
    var service = workflowsMaintenanceService;
    var topics;
    var actions;

    vm.$onInit = onInit;

    function onInit() {
        vm.canEdit = viewData.canEdit;
        vm.criteria = viewData;
        vm.isSaveEnabled = isSaveEnabled;
        vm.isDiscardEnabled = isDiscardEnabled;
        vm.save = save;
        vm.discard = discard;
        $rootScope.setPageTitlePrefix(viewData.criteriaId, 'workflows.details');

        topics = {
            chars: {
                key: 'characteristics',
                title: 'Characteristics',
                template: '<ip-maintain-characteristics data-topic="$topic" />',
                params: {
                    criteriaId: viewData.criteriaId,
                    canEdit: viewData.canEdit,
                    canEditProtected: viewData.canEditProtected,
                    hasOffices: viewData.hasOffices
                }
            },
            events: {
                key: 'events',
                title: 'workflows.maintenance.events.eventControl',
                template: '<ip-workflows-maintenance-events data-topic="$topic" />',
                params: {
                    criteriaId: viewData.criteriaId,
                    canEdit: viewData.canEdit,
                    canEditProtected: viewData.canEditProtected
                }
            },
            entries: {
                key: 'entries',
                title: 'workflows.maintenance.entries.entryControl',
                template: '<ip-workflows-maintenance-entries data-topic="$topic" />',
                params: {
                    criteriaId: viewData.criteriaId,
                    canEdit: viewData.canEdit
                }
            }
        };

        actions = {
            resetInheritance: {
                key: 'resetInheritance',
                title: 'workflows.actions.resetInheritance.title',
                action: resetInheritance,
                disabled: !viewData.isInherited,
                tooltip: !viewData.isInherited ? 'workflows.actions.resetInheritance.disabledMaintenanceTooltip' : null
            },
            breakInheritance: {
                key: 'breakInheritance',
                title: 'workflows.actions.breakInheritance.title',
                action: breakInheritance,
                disabled: !viewData.isInherited,
                tooltip: !viewData.isInherited ? 'workflows.actions.breakInheritance.disabledMaintenanceTooltip' : null
            }
        };

        vm.options = {
            topics: [topics.chars, topics.events, topics.entries],
            actions: vm.canEdit ? [actions.resetInheritance, actions.breakInheritance] : []
        };

        vm.lastSearch = sharedService.lastSearch;
        vm.permissionAlertOptions = viewData;
        vm.onTopicSelected = onTopicSelected;

        setLastSearchIfEmpty();
    }

    function setLastSearchIfEmpty() {
        var args = store.local.get('lastSearch');
        if (!vm.lastSearch && args) {
            var searchByIds = Array.isArray(args[0]);
            vm.lastSearch = new LastSearch({
                method: searchByIds ? workflowsSearchService.searchByIds : workflowsSearchService.search,
                methodName: searchByIds ? 'searchByIds' : 'search',
                args: [args[0], args[1]]
            });
        }
    }

    function isSaveEnabled() {
        if (!topics.chars.initialised) {
            return false;
        }

        return !topics.chars.hasError() && topics.chars.isDirty();
    }

    function isDiscardEnabled() {
        if (!topics.chars.initialised) {
            return false;
        }

        return topics.chars.isDirty();
    }

    function discard() {
        return topics.chars.discard();
    }

    function flatten(topics, output) {
        _.each(topics, function (topic) {
            output.push(topic);
            if (topic.topics) {
                flatten(topic.topics, output);
            }
        });
    }

    function onTopicSelected(topicKey) {
        var flattenTopics = [];
        flatten(topics, flattenTopics);
        _.each(flattenTopics, function (topic) {
            if (topic.key === topicKey) {
                if (_.isFunction(topic.initializeShortcuts)) {
                    topic.initializeShortcuts();
                }
            }
        });
    }

    function save() {
        var formData = topics.chars.getFormData();
        return service.save(viewData.criteriaId, formData).then(function (response) {
            if (topics.chars.validateSaveResponse(response.data)) {
                var showPolicingAlert = topics.chars.showPolicingAlertOnSave();
                topics.chars.afterSave(response.data);

                if (showPolicingAlert) {
                    notificationService
                        .info({
                            message: 'workflows.maintenance.save'
                        });
                } else {
                    notificationService.success();
                }
            } else {
                var translationData = {};
                if (response.data.error.field === 'characteristicsDuplicate') {
                    translationData = {
                        criteriaId: response.data.error.message
                    }
                }
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: $translate.instant('workflows.maintenance.errors.' + response.data.error.field, translationData)
                });
            }
        });
    }

    function resetInheritance() {
        if (!viewData.isInherited) {
            return;
        }

        confirmResetInheritance().then(function (applyToDescendants) {
            return service.resetWorkflow(viewData.criteriaId, applyToDescendants)
                .then(function (result) {
                    if (result.status === 'updateNameRespOnCases') {
                        modalService.openModal({
                            id: 'ChangeDueDateRespConfirm',
                            preSave: true
                        }).then(function (updateDueDate) {
                            service.resetWorkflow(viewData.criteriaId, applyToDescendants, updateDueDate)
                                .then(function (result) {
                                    resetSuccess(result);
                                });
                        });
                    } else {
                        resetSuccess(result);
                    }
                });
        });
    }

    function resetSuccess(data) {
        if (data.usedByCase) {
            return notificationService.info({
                title: "workflows.inheritance.policingNotification.title",
                message: "workflows.inheritance.policingNotification.message",
                messageParams: {
                    criteriaId: viewData.criteriaId
                }
            }).then(function () {
                successReload();
            });
        }
        successReload();
    }

    function successReload() {
        notificationService.success();
        // avoid unsaved changes notification
        vm.isSaveEnabled = _.constant(false);
        $state.reload($state.current.name);
    }

    function confirmResetInheritance() {
        return service.getDescendants(viewData.criteriaId)
            .then(function (data) {
                return modalService.open('InheritanceResetConfirmation', null, {
                    viewData: {
                        criteriaId: viewData.criteriaId,
                        items: data.descendants,
                        parent: data.parent,
                        context: 'criteria'
                    }
                });
            });
    }

    function breakInheritance() {
        if (!viewData.isInherited) {
            return;
        }

        return workflowsMaintenanceService.getParent(viewData.criteriaId).then(function (data) {
            return modalService.openModal({
                id: 'InheritanceBreakConfirmation',
                parent: data,
                criteriaId: viewData.criteriaId,
                context: 'criteria'
            });
        }).then(function () {
            workflowInheritanceService.breakInheritance(viewData.criteriaId).then(function () {
                successReload();
            });
        });
    }
});
