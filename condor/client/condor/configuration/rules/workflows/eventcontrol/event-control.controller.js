angular.module('inprotech.configuration.rules.workflows').controller('WorkflowsEventControlController',
    function ($scope, $state, $translate, viewData, utils, workflowsMaintenanceEventsService,
        workflowsMaintenanceService, workflowsEventControlService,
        notificationService, modalService, bus, $rootScope) {
        'use strict';
        var vm = this;
        var service;
        var eventControlService;
        var topics;
        var topicGroups;
        var actions;

        vm.$onInit = onInit;

        function onInit() {
            service = workflowsMaintenanceEventsService;
            eventControlService = workflowsEventControlService;

            vm.eventControl = viewData;
            vm.parentData = viewData.parent;
            vm.workflowEventIds = service.eventIds();
            vm.canEdit = viewData.canEdit;
            vm.isSaveEnabled = isSaveEnabled;
            vm.isDiscardEnabled = isDiscardEnabled;
            vm.isDeleteEnabled = _.constant(true);
            vm.discard = discard;
            vm.onSaveClick = onSaveClick;
            vm.delete = deleteEvent;
            vm.isInherited = viewData.inherited;
            vm.canDelete = viewData.canDelete;
            vm.isSaveDiscardAvailable = function () {
                return vm.canEdit;
            };

            // DueDate and StandinInstruction sections both use it
            viewData.dueDateDependsOnStandingInstruction = false;
            viewData.dueDateCalcMaxCycles = 0;
            vm.onTopicSelected = onTopicSelected;

            $rootScope.setPageTitlePrefix(viewData.criteriaId + ' (' + viewData.eventId + ')', 'workflows.details.eventcontrol');

            topics = {
                overview: {
                    key: 'overview',
                    title: 'workflows.eventcontrol.overview',
                    template: '<ip-workflows-event-control-overview data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                dueDateCalc: {
                    key: 'dueDateCalc',
                    title: 'workflows.eventcontrol.dueDateCalc.title',
                    subTitle: 'workflows.eventcontrol.dueDateCalc.blurb',
                    template: '<ip-workflows-event-control-duedatecalc data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                eventOccurrence: {
                    key: 'eventOccurrence',
                    title: 'workflows.eventcontrol.eventOccurrence.title',
                    subTitle: 'workflows.eventcontrol.eventOccurrence.blurb',
                    template: '<ip-workflows-event-control-event-occurrence data-topic="$topic" />',
                    subTitleInfoTemplate: 'condor/configuration/rules/workflows/eventcontrol/event-occurrence-popover.html',
                    params: {
                        viewData: viewData
                    }
                },
                syncEventDate: {
                    key: 'syncEventDate',
                    title: 'workflows.eventcontrol.syncEventDate.title',
                    template: '<ip-workflows-event-control-sync-event-date data-topic="$topic" />',
                    info: 'workflows.eventcontrol.syncEventDate.info',
                    params: {
                        viewData: viewData
                    }
                },
                standingInstruction: {
                    key: 'standingInstruction',
                    title: 'workflows.eventcontrol.standingInstruction.title',
                    subTitle: 'workflows.eventcontrol.standingInstruction.blurb',
                    template: '<ip-workflows-event-control-standing-instruction data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                dateComparison: {
                    key: 'dateComparison',
                    title: 'workflows.eventcontrol.dateComparison.title',
                    subTitle: 'workflows.eventcontrol.dateComparison.blurb',
                    template: '<ip-workflows-event-control-date-comparison data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                satisfyingEvents: {
                    key: 'satisfyingEvents',
                    title: 'workflows.eventcontrol.satisfyingEvents.title',
                    info: 'workflows.eventcontrol.satisfyingEvents.info',
                    template: '<ip-workflows-event-control-satisfying-events data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                designatedJurisdictions: {
                    key: 'designatedJurisdictions',
                    title: 'workflows.eventcontrol.designatedJurisdictions.title',
                    info: 'workflows.eventcontrol.designatedJurisdictions.info',
                    template: '<ip-workflows-event-control-designated-jurisdictions data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                changeStatus: {
                    key: 'changeStatus',
                    title: 'workflows.eventcontrol.changeStatus.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    template: '<ip-workflows-event-control-change-status data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                report: {
                    key: 'report',
                    title: 'workflows.eventcontrol.report.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    template: '<ip-workflows-event-control-report data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                changeAction: {
                    key: 'changeAction',
                    title: 'workflows.eventcontrol.changeAction.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    template: '<ip-workflows-event-control-change-action data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                eventsToClear: {
                    key: 'eventsToClear',
                    title: 'workflows.eventcontrol.eventsToClear.title',
                    info: 'workflows.eventcontrol.eventsToClear.info',
                    template: '<ip-workflows-event-control-events-to-clear data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                eventsToUpdate: {
                    key: 'eventsToUpdate',
                    title: 'workflows.eventcontrol.eventsToUpdate.title',
                    info: 'workflows.eventcontrol.eventsToUpdate.info',
                    template: '<ip-workflows-event-control-events-to-update data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                nameChange: {
                    key: 'nameChange',
                    title: 'workflows.eventcontrol.nameChange.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    infoTemplate: 'condor/configuration/rules/workflows/eventcontrol/name-change-popover.html',
                    template: '<ip-workflows-event-control-name-change data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                ptaDelaysCalc: {
                    key: 'ptaDelaysCalc',
                    title: 'workflows.eventcontrol.ptaDelaysCalc.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    info: 'workflows.eventcontrol.ptaDelaysCalc.info',
                    template: '<ip-workflows-event-control-pta-delays-calc data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }

                },
                reminders: {
                    key: 'reminders',
                    title: 'workflows.eventcontrol.reminders.title',
                    infoTemplate: 'condor/configuration/rules/workflows/eventcontrol/reminders-info-popover.html',
                    template: '<ip-workflows-event-control-reminders data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                documents: {
                    key: 'documents',
                    title: 'workflows.eventcontrol.documents.title',
                    emptyGridNotification: 'workflows.eventcontrol.documents.emptyGridNotification',
                    info: 'workflows.eventcontrol.documents.info',
                    template: '<ip-workflows-event-control-documents data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                charges: {
                    key: 'charges',
                    title: 'workflows.eventcontrol.charges.title',
                    subTitle: 'workflows.eventcontrol.whenCurrentEventUpdates',
                    template: '<ip-workflows-event-control-charges data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                },
                dateLogic: {
                    key: 'dateLogic',
                    title: 'workflows.eventcontrol.dateLogic.title',
                    info: 'workflows.eventcontrol.dateLogic.info',
                    template: '<ip-workflows-event-control-date-logic data-topic="$topic" />',
                    params: {
                        viewData: viewData
                    }
                }
            };

            topicGroups = {
                calculations: {
                    key: 'calculationsGroup',
                    title: 'workflows.eventcontrol.groupSections.calculations',
                    subTitle: 'workflows.eventcontrol.groupSections.calculationsDescription',
                    topics: [topics.dueDateCalc, topics.eventOccurrence, topics.syncEventDate]
                },
                conditions: {
                    key: 'conditionsGroup',
                    title: 'workflows.eventcontrol.groupSections.conditions',
                    subTitle: 'workflows.eventcontrol.groupSections.conditionsDescription',
                    topics: [
                        topics.standingInstruction,
                        topics.dateComparison,
                        topics.satisfyingEvents,
                        viewData.designatedJurisdictions && topics.designatedJurisdictions
                    ]
                },
                eventOutcomes: {
                    key: 'eventOutcomesGroup',
                    title: 'workflows.eventcontrol.groupSections.eventOutcomes',
                    subTitle: 'workflows.eventcontrol.groupSections.eventOutcomesDescription',
                    topics: [topics.changeStatus, topics.report, topics.changeAction, topics.eventsToClear, topics.eventsToUpdate, topics.nameChange, topics.ptaDelaysCalc]
                },
                eventOutput: {
                    key: 'eventOutputGroup',
                    title: 'workflows.eventcontrol.groupSections.eventOutput',
                    subTitle: 'workflows.eventcontrol.groupSections.eventOutputDescription',
                    topics: [topics.reminders, topics.documents, topics.charges]
                },
                validations: {
                    key: 'validationsGroup',
                    title: 'workflows.eventcontrol.groupSections.validations',
                    subTitle: 'workflows.eventcontrol.groupSections.validationsDescription',
                    topics: [topics.dateLogic]
                }
            };

            actions = {
                resetInheritance: {
                    key: 'resetInheritance',
                    title: 'workflows.actions.resetInheritance.title',
                    action: resetEventInheritance,
                    disabled: !viewData.canResetInheritance,
                    tooltip: !viewData.canResetInheritance ? 'workflows.actions.resetInheritance.disabledEventTooltip' : null
                },
                breakInheritance: {
                    key: 'breakInheritance',
                    title: 'workflows.actions.breakInheritance.title',
                    action: breakEventInheritance,
                    disabled: !viewData.isInherited,
                    tooltip: !viewData.isInherited ? 'workflows.actions.breakInheritance.disabledEventTooltip' : null
                }
            };

            vm.topicOptions = {
                topics: [topics.overview, topicGroups.calculations, topicGroups.conditions, topicGroups.eventOutcomes, topicGroups.eventOutput, topicGroups.validations],
                actions: vm.canEdit ? [actions.resetInheritance, actions.breakInheritance] : []
            };

            vm.$topics = topics;
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

        function isSaveEnabled() {
            return isDirty() && !hasError();
        }

        function isDiscardEnabled() {
            return isDirty();
        }

        function deleteEvent() {
            if (!vm.workflowEventIds.length) {
                return;
            }

            var eventIds = [viewData.eventId];

            service.confirmDeleteWorkflow($scope, viewData.criteriaId, eventIds)
                .then(function (confirmation) {
                    return service.deleteEvents(viewData.criteriaId, eventIds, Boolean(confirmation.applyToDescendants));
                })
                .then(function () {
                    navigateToNext();
                });
        }

        function isDirty() {
            return _.any(topics, function (topic) {
                return topic.isDirty && topic.isDirty();
            });
        }

        function hasError() {
            return _.any(topics, function (topic) {
                return topic.hasError && topic.hasError();
            });
        }

        function discard() {
            reload();
        }

        function onSaveClick() {
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
                showSaveError(errorTopics);
                return;
            }

            var isInherited = viewData.isInherited;
            var hasChildren = viewData.hasChildren;
            var hasDueDateOnCase = viewData.hasDueDateOnCase;
            var applyToDescendants = false,
                changeDueDateResp = false;

            utils.steps(function (next) {
                if (hasDueDateOnCase && topics.overview.isRespChanged()) {
                    modalService.openModal({
                        id: 'ChangeDueDateRespConfirm'
                    }).then(function (result) {
                        changeDueDateResp = result;
                        next();
                    });
                } else {
                    next();
                }
            }, function (next) {
                if (isInherited) {
                    notificationService.confirm({
                        title: 'Warning',
                        messages: ['workflows.eventcontrol.breakInheritanceConfirmation', 'workflows.eventcontrol.doYouWantToProceed'],
                        cancel: 'Cancel',
                        continue: 'Proceed'
                    }).then(next);
                } else {
                    next();
                }
            }, function (next) {
                if (hasChildren) {
                    service.getDescendants(viewData.criteriaId, [viewData.eventId], true)
                        .then(function (data) {
                            modalService.open('EventInheritanceConfirmation', null, {
                                viewData: {
                                    items: data.descendants
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
                save(applyToDescendants, changeDueDateResp);
            });
        }

        function save(applyToDescendants, changeDueDateResp) {
            var formData = {
                applyToDescendants: applyToDescendants,
                changeRespOnDueDates: changeDueDateResp
            };

            _.each(topics, function (t) {
                if (_.isFunction(t.getFormData)) {
                    _.extend(formData, t.getFormData());
                }
            });

            return eventControlService.updateEventControl(viewData.criteriaId, viewData.eventId, formData).then(function (result) {
                //todo: remove afterSave in overview
                //topics.overview.afterSave();
                if (result.status === 'success') {
                    notificationService.success();
                    reload();
                    bus.channel('gridRefresh.eventResults').broadcast();
                } else {
                    if (result.errors && result.errors.length) {
                        var errors = result.errors.map(function (e) {
                            var topic = topics[e.topic];
                            return $translate.instant(topic.title) + ' - ' + e.message;
                        });
                        showSaveError(errors);
                    }
                }
            });
        }

        function showSaveError(errors) {
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'sections.errors.errorInSection',
                errors: errors,
                actionMessage: 'sections.errors.actionMessage'
            });
        }

        function reload() {
            // avoid unsaved changes notification
            vm.isSaveEnabled = _.constant(false);
            $state.reload($state.current.name);
        }

        function navigateToNext() {
            vm.isSaveEnabled = _.constant(false);
            var index = _.indexOf(vm.workflowEventIds, parseInt(viewData.eventId));
            var total = vm.workflowEventIds ? vm.workflowEventIds.length : 0;
            var stateParam = {
                eventId: viewData.eventId
            }

            bus.channel('gridRefresh.eventResults').broadcast();

            if (total <= 1) {
                $state.go('^', null, {
                    location: 'replace'
                });
                return;
            } else if (index < total - 1) {
                stateParam.eventId = vm.workflowEventIds[index + 1];
            } else if (index === total - 1) {
                stateParam.eventId = vm.workflowEventIds[index - 1];
            }

            vm.workflowEventIds.splice(index, 1);
            $state.go('workflows.details.eventcontrol', stateParam, {
                location: 'replace'
            });
        }

        function resetEventInheritance() {
            if (!viewData.canResetInheritance) {
                return;
            }

            confirmResetInheritance().then(function (applyToDescendants) {
                eventControlService.resetEvent(viewData.criteriaId, viewData.eventId, applyToDescendants)
                    .then(function (result) {
                        if (result.status === 'updateNameRespOnCases') {
                            modalService.openModal({
                                id: 'ChangeDueDateRespConfirm',
                                preSave: true
                            }).then(function (updateDueDate) {
                                eventControlService.resetEvent(viewData.criteriaId, viewData.eventId, applyToDescendants, updateDueDate)
                                    .then(function () {
                                        resetSuccess();
                                    });
                            });
                        } else {
                            resetSuccess();
                        }
                    });
            });
        }

        function breakEventInheritance() {
            if (!viewData.isInherited) {
                return;
            }

            return workflowsMaintenanceService.getParent(viewData.criteriaId).then(function (data) {
                return modalService.openModal({
                    id: 'InheritanceBreakConfirmation',
                    parent: data,
                    context: 'eventcontrol'
                });
            }).then(function () {
                eventControlService.breakEventInheritance(viewData.criteriaId, viewData.eventId).then(function () {
                    resetSuccess();
                });
            });
        }

        function resetSuccess() {
            notificationService.success();
            bus.channel('gridRefresh.eventResults').broadcast();
            reload();
        }

        function confirmResetInheritance() {
            return service.getDescendants(viewData.criteriaId, [viewData.eventId], true)
                .then(function (data) {
                    return modalService.open('InheritanceResetConfirmation', null, {
                        viewData: {
                            criteriaId: viewData.criteriaId,
                            items: data.descendants,
                            parent: data.parent,
                            context: 'eventcontrol'
                        }
                    });
                });
        }
    });