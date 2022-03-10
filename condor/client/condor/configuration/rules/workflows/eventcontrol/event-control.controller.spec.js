describe('WorkflowsEventControlController', function() {
    'use strict';

    var controller, maintenanceService, maintainEventsService, eventControlService, notificationService, modalService, topics, promiseMock,
        stateService, bus, rootScope;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            maintenanceService = test.mock('workflowsMaintenanceService');
            maintainEventsService = test.mock('workflowsMaintenanceEventsService');
            eventControlService = test.mock('workflowsEventControlService');
            notificationService = test.mock('notificationService');
            modalService = test.mock('modalService', 'modalServiceMock');
            promiseMock = test.mock('promise');
            stateService = test.mock('$state', 'stateMock');
            bus = test.mock('bus', 'BusMock');
            rootScope = {
                setPageTitlePrefix: jasmine.createSpy('setPageTitlePrefix').and.stub()
            };
        });

        inject(function($controller) {
            controller = function(extendData) {
                var data = {
                    criteriaId: -1,
                    eventId: -2,
                    overview: {
                        description: 'overview'
                    },
                    syncedEventSettingsL: {
                        dateAdjustmentOptions: []
                    }
                };

                _.extend(data, extendData);

                var returnController = $controller('WorkflowsEventControlController', {
                    $scope: {},
                    viewData: data,
                    $rootScope: rootScope
                });

                returnController.$onInit();
                topics = returnController.$topics;

                return returnController;
            };
        });
    });

    beforeEach(function() {
        eventControlService.updateEventControl.returnValue = {
            status: 'success'
        };
    });

    describe('initialisation', function() {
        it('should set eventControl', function() {
            maintainEventsService.eventIds = _.constant([-1, -2, -3]);
            var c = controller({
                canEdit: {},
                canDelete: true
            });

            expect(c.eventControl).toBeDefined();
            expect(c.workflowEventIds).toEqual([-1, -2, -3]);
            expect(c.canEdit).toBeDefined();
            expect(c.isSaveEnabled).toBeDefined();
            expect(c.isDiscardEnabled).toBeDefined();
            expect(c.isDeleteEnabled()).toEqual(true);
            expect(c.discard).toBeDefined();
            expect(c.onSaveClick).toBeDefined();
            expect(c.delete).toBeDefined();
            expect(c.canDelete).toEqual(true);
            expect(c.isSaveDiscardAvailable()).toEqual(c.canEdit);
            expect(rootScope.setPageTitlePrefix).toHaveBeenCalled();
        });

        it('should call to set page title prefix', function() {
            var details = {
                eventId: 9090,
                criteriaId: 1111
            };
            controller(details);

            var prefix = details.criteriaId + ' (' + details.eventId + ')';
            expect(rootScope.setPageTitlePrefix).toHaveBeenCalledWith(prefix, 'workflows.details.eventcontrol');
        });
    })

    describe('reset inheritance action', function() {
        it('should initialise actions if can edit', function() {
            var c = controller({
                canEdit: true,
                canResetInheritance: true
            });

            expect(c.topicOptions.actions.length).toEqual(2);
            expect(c.topicOptions.actions[0].disabled).toEqual(false);
            expect(c.topicOptions.actions[0].tooltip).toEqual(null);
        });

        it('should not initialise actions if cannot edit', function() {
            var c = controller({
                canEdit: false,
                canResetInheritance: true
            });

            expect(c.topicOptions.actions.length).toEqual(0);
        });

        it('should disable reset inheritance if cannot reset', function() {
            var c = controller({
                canEdit: true,
                canResetInheritance: false
            });

            expect(c.topicOptions.actions[0].disabled).toEqual(true);
            expect(c.topicOptions.actions[0].tooltip).not.toEqual(null);
        });

        it('should check for descendants and reset event', function() {
            var c = controller({
                canEdit: true,
                canResetInheritance: true
            });
            var parent = { id: 1 };
            var descendants = [{ id: 2 }, { id: 3 }];
            maintainEventsService.getDescendants = promiseMock.createSpy({ parent: parent, descendants: descendants });
            eventControlService.resetEvent = promiseMock.createSpy({ status: 'success' });
            modalService.open = promiseMock.createSpy(true);

            c.topicOptions.actions[0].action();

            expect(maintainEventsService.getDescendants).toHaveBeenCalled();
            expect(modalService.open).toHaveBeenCalledWith('InheritanceResetConfirmation', null, {
                viewData: {
                    criteriaId: -1,
                    items: descendants,
                    parent: parent,
                    context: 'eventcontrol'
                }
            });
            expect(eventControlService.resetEvent).toHaveBeenCalledWith(-1, -2, true);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();

            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
            expect(bus.channel().broadcast).toHaveBeenCalled();
        });

        it('should ask to update due date responsible name if required', function() {
            var c = controller({
                canEdit: true,
                canResetInheritance: true
            });
            var parent = { id: 1 };
            var descendants = [];
            maintainEventsService.getDescendants = promiseMock.createSpy({ parent: parent, descendants: descendants });
            eventControlService.resetEvent = promiseMock.createSpy({ status: 'updateNameRespOnCases' });
            modalService.openModal = promiseMock.createSpy(true);
            modalService.open = promiseMock.createSpy(true);

            c.topicOptions.actions[0].action();

            expect(modalService.openModal).toHaveBeenCalledWith({ id: 'ChangeDueDateRespConfirm', preSave: true });
            expect(eventControlService.resetEvent).toHaveBeenCalledWith(-1, -2, true, true);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();

            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
            expect(bus.channel().broadcast).toHaveBeenCalled();
        });
    });

    describe('break inheritance action', function() {
        it('should initialise action if can edit and inherited', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });

            expect(c.topicOptions.actions.length).toEqual(2);
            expect(c.topicOptions.actions[1].disabled).toEqual(false);
            expect(c.topicOptions.actions[1].tooltip).toEqual(null);
        });

        it('should not initialise action if cannot edit', function() {
            var c = controller({
                canEdit: false,
                isInherited: true
            });

            expect(c.topicOptions.actions.length).toEqual(0);
        });

        it('should disable break inheritance if not inherited', function() {
            var c = controller({
                canEdit: true,
                isInherited: false
            });

            expect(c.topicOptions.actions[1].disabled).toEqual(true);
            expect(c.topicOptions.actions[1].tooltip).not.toEqual(null);
        });

        it('should show confirmation and then break inheritance', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });
            var parent = { id: 1, description: 'ddddd' };
            maintenanceService.getParent = promiseMock.createSpy(parent);
            modalService.openModal = promiseMock.createSpy();
            eventControlService.breakEventInheritance = promiseMock.createSpy();

            c.topicOptions.actions[1].action();


            expect(maintenanceService.getParent).toHaveBeenCalledWith(-1);
            expect(modalService.openModal).toHaveBeenCalledWith({
                id: 'InheritanceBreakConfirmation',
                parent: parent,
                context: 'eventcontrol'
            });
            expect(eventControlService.breakEventInheritance).toHaveBeenCalledWith(-1, -2);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();

            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
            expect(bus.channel().broadcast).toHaveBeenCalled();
        });
    });

    describe('enable buttons', function() {
        it('should enable save if no error and dirty', function() {
            var c = controller();
            topics.overview.hasError = _.constant(false);
            topics.overview.isDirty = _.constant(true);
            expect(c.isSaveEnabled()).toBe(true);

            topics.overview.hasError = _.constant(true);
            topics.overview.isDirty = _.constant(true);
            expect(c.isSaveEnabled()).toBe(false);

            topics.overview.hasError = _.constant(false);
            topics.overview.isDirty = _.constant(false);
            expect(c.isSaveEnabled()).toBe(false);

        });

        it('should enable discard when dirty', function() {
            var c = controller();
            topics.overview.isDirty = _.constant(true);
            expect(c.isDiscardEnabled()).toBe(true);

            topics.overview.isDirty = _.constant(false);
            expect(c.isDiscardEnabled()).toBe(false);
        });
    });

    describe('discard', function() {
        it('should discard each editable topic', function() {
            var c = controller();
            c.discard();
            expect(stateService.reload).toHaveBeenCalled();
        });
    });

    describe('save', function() {
        var c;

        it('should not save changes if validate fails for any topic', function() {
            c = controller({});
            topics.syncEventDate.validate = jasmine.createSpy().and.returnValue(false);

            c.onSaveClick();

            expect(topics.syncEventDate.validate).toHaveBeenCalled();
            expect(notificationService.confirm).not.toHaveBeenCalled();
            expect(modalService.open).not.toHaveBeenCalled();
            expect(eventControlService.updateEventControl).not.toHaveBeenCalled();
            expect(notificationService.success).not.toHaveBeenCalled();
            expect(stateService.reload).not.toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should save changes and perform post save tasks', function() {
            setupController();

            c.onSaveClick();

            expect(topics.syncEventDate.validate).toHaveBeenCalled();
            expect(topics.overview.getFormData).toHaveBeenCalled();
            expect(topics.dueDateCalc.getFormData).toHaveBeenCalled();
            expect(topics.syncEventDate.getFormData).toHaveBeenCalled();
            expect(topics.dateComparison.getFormData).toHaveBeenCalled();
            expect(eventControlService.updateEventControl).toHaveBeenCalledWith(-1, -2, jasmine.objectContaining({
                applyToDescendants: false,
                changeRespOnDueDates: false
            }));
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
        });

        it('should show dialog if due date has used by case and with change of responsibility', function() {
            setupController(false, false, true);
            topics.overview.isRespChanged = _.constant(true);

            modalService.openModal = promiseMock.createSpy(true);

            c.onSaveClick();

            expect(eventControlService.updateEventControl).toHaveBeenCalledWith(-1, -2, jasmine.objectContaining({
                changeRespOnDueDates: true
            }));
        });

        it('should not show dialog if due date has used by case but without change of responsibility', function() {
            setupController(false, false, true);
            topics.overview.isRespChanged = _.constant(false);

            modalService.open = promiseMock.createSpy(true);

            c.onSaveClick();

            expect(eventControlService.updateEventControl).toHaveBeenCalledWith(-1, -2, jasmine.objectContaining({
                changeRespOnDueDates: false
            }));
        });

        it('should show message if has parent', function() {
            setupController(true);

            c.onSaveClick();

            expect(notificationService.confirm).toHaveBeenCalledWith(jasmine.objectContaining({
                messages: ['workflows.eventcontrol.breakInheritanceConfirmation', 'workflows.eventcontrol.doYouWantToProceed']
            }));
            expect(modalService.open).not.toHaveBeenCalled();
            expect(topics.overview.getFormData).toHaveBeenCalled();
            expect(eventControlService.updateEventControl).toHaveBeenCalledWith(-1, -2, jasmine.objectContaining({
                applyToDescendants: false
            }));
        });

        it('should show message if has children and pass apply to descendants', function() {
            var getDescendantsResult = {
                descendants: [{
                    id: 1,
                    description: "testEventDelete"
                }]
            };
            maintainEventsService.getDescendants = promiseMock.createSpy(getDescendantsResult);
            setupController(false, true);
            modalService.open = promiseMock.createSpy(true);

            c.onSaveClick();

            expect(notificationService.confirm).not.toHaveBeenCalledWith(jasmine.objectContaining({
                messages: ['workflows.eventcontrol.breakInheritanceConfirmation', 'workflows.eventcontrol.doYouWantToProceed']
            }));
            expect(maintainEventsService.getDescendants).toHaveBeenCalled();
            expect(modalService.open).toHaveBeenCalledWith('EventInheritanceConfirmation', null, { viewData: { items: getDescendantsResult.descendants } });
            expect(topics.overview.getFormData).toHaveBeenCalled();
            expect(eventControlService.updateEventControl).toHaveBeenCalledWith(-1, -2, jasmine.objectContaining({
                applyToDescendants: true
            }));
        });

        it('should show server validation message', function() {
            setupController(false, false, false);

            eventControlService.updateEventControl.returnValue = {
                status: 'error',
                errors: [{
                    topic: 'dueDateCalc',
                    message: 'some server error'
                }]
            };

            c.onSaveClick();

            expect(topics.syncEventDate.validate).toHaveBeenCalled();
            expect(eventControlService.updateEventControl).toHaveBeenCalled();
            expect(notificationService.success).not.toHaveBeenCalled();
            expect(stateService.reload).not.toHaveBeenCalled();
            expect(notificationService.alert).toHaveBeenCalled();

            var alertArgs = notificationService.alert.calls.argsFor(0);
            expect(alertArgs[0].errors[0]).toEqual('workflows.eventcontrol.dueDateCalc.title - some server error');
        });

        describe('delete', function() {
            var c;

            beforeEach(function() {
                var confirmationMock = { applyToDescendants: false };
                maintainEventsService.confirmDeleteWorkflow = promiseMock.createSpy(confirmationMock);
                modalService.open = promiseMock.createSpy(true);
            });

            it('should delete the event', function() {
                maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                c = setup();
                c.delete();

                expect(maintainEventsService.confirmDeleteWorkflow).toHaveBeenCalledWith(jasmine.any(Object), c.eventControl.criteriaId, [c.eventControl.eventId]);
                expect(maintainEventsService.deleteEvents).toHaveBeenCalled();
                expect(stateService.go).toHaveBeenCalled();
            });

            it('should broadcast a message to the events grid to refresh', function() {
                maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                c = setup();
                c.delete();

                expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
                expect(bus.channel().broadcast).toHaveBeenCalled();
            });

            it('should show message if has parent', function() {
                maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                c = setup(true);
                c.delete();

                expect(notificationService.confirmDelete).toHaveBeenCalled;

                expect(modalService.open).not.toHaveBeenCalled();

                expect(maintainEventsService.deleteEvents).toHaveBeenCalledWith(-1, [-2], false);
            });

            it('should show message if has children and pass apply to descendants', function() {
                maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                c = setup(false, true);
                var descendents = [{
                    id: 1,
                    description: "testEventDelete"
                }];

                maintainEventsService.confirmDeleteWorkflow = promiseMock.createSpy({
                    applyToDescendants: true
                });
                maintainEventsService.getDescendants = promiseMock.createSpy(descendents);

                c.delete();

                expect(maintainEventsService.deleteEvents).toHaveBeenCalledWith(-1, [-2], true);
            });

            describe('navigation after delete', function() {
                it('should move to next item after deletion', function() {
                    maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                    c = setup();

                    c.delete();

                    expect(maintainEventsService.deleteEvents).toHaveBeenCalled();
                    expect(stateService.go).toHaveBeenCalledWith('workflows.details.eventcontrol', {
                        eventId: 3
                    }, { location: 'replace' });
                    expect(maintainEventsService.eventIds().length).toEqual(4);
                });

                it('should move to previous item if last one is deleted', function() {
                    maintainEventsService.eventIds.returnValue = [-5, 0, 1, -2, 3];
                    c = setup();
                    c.delete();

                    expect(maintainEventsService.deleteEvents).toHaveBeenCalled();
                    expect(stateService.go).toHaveBeenCalledWith('workflows.details.eventcontrol', {
                        eventId: 3
                    }, { location: 'replace' });
                    expect(maintainEventsService.eventIds().length).toEqual(4);
                });

                it('should move to Criteria detail page if only event is deleted', function() {
                    maintainEventsService.eventIds.returnValue = [-2];
                    c = setup();
                    c.delete();

                    expect(maintainEventsService.deleteEvents).toHaveBeenCalled();
                    expect(stateService.go).toHaveBeenCalledWith('^', null, { location: 'replace' });
                    expect(maintainEventsService.eventIds().length).toEqual(1);
                });
            });

            function setup(isInherited, hasChildren) {
                var data = {
                    criteriaId: -1,
                    eventId: -2,
                    overview: {
                        description: 'overview'
                    },
                    syncedEventSettingsL: {
                        dateAdjustmentOptions: []
                    }
                };

                var eventController = controller('WorkflowsEventControlController', {
                    $scope: {},
                    viewData: data,
                    isInherited: isInherited,
                    hasChildren: hasChildren
                });

                return eventController;
            }
        });

        function setupController(isInherited, hasChildren, hasDueDateOnCase) {
            c = controller({
                isInherited: isInherited,
                hasChildren: hasChildren,
                hasDueDateOnCase: hasDueDateOnCase
            });
            maintainEventsService.deleteEvents = promiseMock.createSpy();
            topics.syncEventDate.validate = jasmine.createSpy().and.returnValue(true);

            topics.overview.getFormData = jasmine.createSpy();
            topics.dueDateCalc.getFormData = jasmine.createSpy();
            topics.syncEventDate.getFormData = jasmine.createSpy();
            topics.dateComparison.getFormData = jasmine.createSpy();
        }
    });
});