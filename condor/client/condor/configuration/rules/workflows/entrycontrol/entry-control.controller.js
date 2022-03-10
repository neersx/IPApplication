angular.module('inprotech.configuration.rules.workflows')
    .controller('WorkflowsEntryControlController', function ($scope, $stateParams, viewData,
        workflowsMaintenanceService, workflowsMaintenanceEntriesService, workflowsEntryControlService,
        notificationService, modalService, utils, $state, bus, $rootScope) {
        'use strict';
        var service;
        var entryService;
        var actions;
        var topics;
        var vm = this;

        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEntryControlService;
            entryService = workflowsMaintenanceEntriesService;
            vm.entryControl = viewData;
            vm.workflowEntryIds = entryService.entryIds();
            vm.canEdit = viewData.canEdit;
            vm.isSaveEnabled = isSaveEnabled;
            vm.isDiscardEnabled = isDiscardEnabled;
            vm.save = save;
            vm.discard = discard;
            vm.delete = deleteEntry;
            vm.isDeleteEnabled = isDeleteEnabled;
            vm.onTopicSelected = onTopicSelected;

            $rootScope.setPageTitlePrefix(viewData.criteriaId + ' (' + viewData.description + ')', 'workflows.details.entrycontrol');

            topics = {
                definition: {
                    key: 'definition',
                    title: 'workflows.entrycontrol.definition.title',
                    template: '<ip-workflows-entry-control-definition data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                details: {
                    key: 'details',
                    title: 'workflows.entrycontrol.details.title',
                    subTitle: 'workflows.entrycontrol.details.blurb',
                    template: '<ip-workflows-entry-control-details data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                steps: {
                    key: 'steps',
                    title: 'workflows.entrycontrol.steps.topicTitle',
                    subTitle: 'workflows.entrycontrol.steps.blurb',
                    template: '<ip-workflows-entry-control-steps data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                displayConditions: {
                    key: 'displayConditions',
                    title: 'workflows.entrycontrol.displayConditions.title',
                    subTitle: 'workflows.entrycontrol.displayConditions.blurb',
                    template: '<ip-workflows-entry-control-display-conditions data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                changeStatus: {
                    key: 'changeStatus',
                    title: 'workflows.entrycontrol.changeStatus.title',
                    subTitle: 'workflows.entrycontrol.changeStatus.blurb',
                    template: '<ip-workflows-entry-control-change-status data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                documents: {
                    key: 'documents',
                    title: 'workflows.entrycontrol.documents.title',
                    subTitle: 'workflows.entrycontrol.documents.blurb',
                    template: '<ip-workflows-entry-control-documents data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                }
            };

            if (viewData.showUserAccess) {
                topics.userAccess = {
                    key: 'userAccess',
                    title: 'workflows.entrycontrol.userAccess.topicTitle',
                    subTitle: 'workflows.entrycontrol.userAccess.blurb',
                    template: '<ip-workflows-entry-control-user-access data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                };
            }
            actions = {
                resetInheritance: {
                    key: 'resetInheritance',
                    title: 'workflows.actions.resetInheritance.title',
                    action: resetEntryInheritance,
                    disabled: !viewData.hasParentEntry,
                    tooltip: !viewData.hasParentEntry ? 'workflows.actions.resetInheritance.disabledEntryTooltip' : null
                },
                breakInheritance: {
                    key: 'breakInheritance',
                    title: 'workflows.actions.breakInheritance.title',
                    action: breakEntryInheritance,
                    disabled: !viewData.hasParentEntry || !viewData.isInherited,
                    tooltip: !viewData.hasParentEntry || !viewData.isInherited ? 'workflows.actions.breakInheritance.disabledEntryTooltip' : null
                }
            };

            initTopicOptions();
        }

        function initTopicOptions() {
            vm.$topics = topics;

            var topicsAvailable;
            if (vm.entryControl.isSeparator) {
                topicsAvailable = [topics.definition];
            } else {
                topicsAvailable = [topics.definition, topics.details, topics.steps, topics.displayConditions, topics.changeStatus, topics.documents];

                if (viewData.showUserAccess) {
                    topicsAvailable.push(topics.userAccess);
                }
            }

            vm.topicOptions = {
                topics: topicsAvailable,
                actions: []
            };

            if (viewData.canEdit) {
                vm.topicOptions.actions = [actions.resetInheritance, actions.breakInheritance];
            }
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

        function ensureAllInitialised() {
            if (!_.all(vm.topicOptions.topics, function (t) {
                return t.initialised;
            })) {
                return false;
            }
            return true;
        }

        function isAnyDirty() {
            return _.any(vm.topicOptions.topics, function (t) {
                return t.isDirty();
            });
        }

        function isSaveEnabled() {
            if (!ensureAllInitialised()) {
                return false;
            }

            return isAnyDirty() && _.all(vm.topicOptions.topics, function (t) {
                return !t.hasError();
            });
        }

        function isDiscardEnabled() {
            if (!ensureAllInitialised()) {
                return false;
            }

            return isAnyDirty();
        }

        function discard() {
            reload();
        }

        function isDeleteEnabled() {
            if (!ensureAllInitialised()) {
                return false;
            }
            return true;
        }

        function deleteEntry() {
            if (!vm.workflowEntryIds.length) {
                return;
            }

            var entryId = [viewData.entryId];
            entryService.confirmDeleteWorkflow($scope, viewData.criteriaId, entryId)
                .then(function (confirmation) {
                    return entryService.deleteEntries(viewData.criteriaId, entryId, Boolean(confirmation.applyToDescendants));
                })
                .then(function () {
                    navigateToNext();
                });
        }

        function save() {
            if (!validateSections()) {
                return;
            }
            var hasParent = viewData.hasParent;
            var hasChildren = viewData.hasChildren;
            var applyToDescendants = false;

            utils.steps(function (next) {
                if (hasParent) {
                    notificationService.confirm({
                        title: 'Warning',
                        messages: ['workflows.entrycontrol.breakInheritanceConfirmation', 'workflows.entrycontrol.doYouWantToProceed'],
                        cancel: 'Cancel',
                        continue: 'Proceed'
                    }).then(next);
                } else {
                    next();
                }
            }, function (next) {
                if (hasChildren) {
                    service.getDescendants(viewData.criteriaId, viewData.entryId, GetEntryDescription())
                        .then(function (resp) {
                            modalService.open('EntryInheritanceConfirmation', null, {
                                viewData: {
                                    items: resp.data.descendants,
                                    breakingItems: resp.data.breaking
                                }
                            }).then(function (result) {
                                applyToDescendants = result;
                                next();
                            });
                        });
                } else {
                    next();
                }
            }, function () {
                updateDetail(applyToDescendants);
            });
        }

        function updateDetail(applyToDescendants) {
            var formData = getData(applyToDescendants);
            return service.updateDetail(viewData.criteriaId, viewData.entryId, formData).then(function (result) {
                if (result.data.status === 'success') {
                    notificationService.success();
                    reload();
                    bus.channel('gridRefresh.entriesResults').broadcast();
                } else {
                    applyError(result.data.errors);
                    notificationService.alert({
                        title: 'modal.unableToComplete',
                        message: 'workflows.entrycontrol.saveError'
                    });
                }
            });
        }

        function getData(applyToDescendants) {
            var data = {
                applyToDescendants: applyToDescendants
            };

            _.each(vm.topicOptions.topics, function (t) {
                data = angular.extend(data, t.getFormData());
            });

            return data;
        }

        function applyError(errors) {
            _.each(vm.topicOptions.topics, function (t) {
                if (t.setError) {
                    t.setError(_.where(errors, {
                        topic: t.key
                    }));
                }
            });
        }

        function reload() {
            vm.isSaveEnabled = _.constant(false);
            $state.reload($state.current.name);
        }

        function GetEntryDescription() {
            return topics.definition.getFormData().description;
        }

        function validateSections() {
            var isInvalid;
            var errorTopics = [];
            _.each(topics, function (t) {
                if (_.isFunction(t.validate) && !t.validate()) {
                    errorTopics.push({
                        message: t.title
                    });
                    isInvalid = true;
                }
            });

            if (isInvalid) {
                notificationService.alert({
                    title: 'modal.unableToComplete',
                    message: 'sections.errors.errorInSection',
                    errors: errorTopics,
                    actionMessage: 'sections.errors.actionMessage'
                });
            }
            return !isInvalid;
        }

        function navigateToNext() {
            vm.isSaveEnabled = _.constant(false);
            var index = _.indexOf(vm.workflowEntryIds, viewData.entryId);
            var total = vm.workflowEntryIds ? vm.workflowEntryIds.length : 0;
            var stateParam = {
                entryId: viewData.entryId
            }

            bus.channel('gridRefresh.entriesResults').broadcast();

            if (total <= 1) {
                $state.go('^', null, {
                    location: 'replace'
                });
                return;
            } else if (index < total - 1) {
                stateParam.entryId = vm.workflowEntryIds[index + 1];
            } else if (index === total - 1) {
                stateParam.entryId = vm.workflowEntryIds[index - 1];
            }

            vm.workflowEntryIds.splice(index, 1);
            $state.go('workflows.details.entrycontrol', stateParam, {
                location: 'replace'
            });
        }

        function resetEntryInheritance() {
            if (!viewData.canEdit || !viewData.hasParentEntry) {
                return;
            }

            confirmResetInheritance().then(function (applyToDescendants) {
                service.resetEntry(viewData.criteriaId, viewData.entryId, applyToDescendants)
                    .then(function () {
                        notificationService.success();
                        reload();
                    });
            });
        }

        function confirmResetInheritance() {
            return service.getDescendantsAndParentWithInheritedEntry(viewData.criteriaId, viewData.entryId).then(function (data) {
                return modalService.open('InheritanceResetConfirmation', null, {
                    viewData: {
                        criteriaId: viewData.criteriaId,
                        items: data.descendants,
                        parent: data.parent,
                        context: 'entrycontrol'
                    }
                });
            });
        }

        function breakEntryInheritance() {
            if (!viewData.canEdit || !viewData.hasParentEntry || !viewData.isInherited) {
                return;
            }

            return workflowsMaintenanceService.getParent(viewData.criteriaId)
                .then(function (data) {
                    return modalService.openModal({
                        id: 'InheritanceBreakConfirmation',
                        parent: data,
                        context: 'entrycontrol'
                    });
                }).then(function () {
                    service.breakEntryInheritance(viewData.criteriaId, viewData.entryId)
                        .then(function () {
                            notificationService.success();
                            reload();
                        });
                });
        }
    });