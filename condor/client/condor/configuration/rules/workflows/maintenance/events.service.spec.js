describe('inprotech.configuration.rules.workflows.workflowsMaintenanceEventsService', function() {
    'use strict';

    var workflowsMaintenanceService, notificationService, service, httpMock, promiseMock, modalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector([
                'inprotech.mocks.configuration.rules.workflows',
                'inprotech.mocks.components.notification',
                'inprotech.mocks.core',
                'inprotech.mocks'
            ]);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            workflowsMaintenanceService = $injector.get('workflowsMaintenanceServiceMock');
            $provide.value('workflowsMaintenanceService', workflowsMaintenanceService);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            promiseMock = $injector.get('promiseMock');
        });

        inject(function(workflowsMaintenanceEventsService) {
            service = workflowsMaintenanceEventsService;
        });
    });

    describe('After Add Event Selected', function() {
        var eventId;

        beforeEach(function() {
            eventId = 123;
        });

        it('should pop up confirmation warning for affecting inherited events', function() {
            service.getDescendantsWithoutEvent = promiseMock.createSpy([{}, {}]);
            service.showInheritanceConfirmationModal = promiseMock.createSpy(true);

            var inheritFlag = service.addEventWorkflow(1, eventId, null);

            expect(service.getDescendantsWithoutEvent).toHaveBeenCalledWith(1, eventId);
            expect(service.getDescendantsWithoutEvent.then).toHaveBeenCalled();
            expect(service.showInheritanceConfirmationModal).toHaveBeenCalled();

            expect(inheritFlag.data).toBe(true);
        });

        it('should not invoke modal if there are no descendants', function() {
            spyOn(service, 'showInheritanceConfirmationModal');
            service.addEvent = promiseMock.createSpy();
            service.getDescendantsWithoutEvent = promiseMock.createSpy([]);

            var result = service.addEventWorkflow(1, eventId, null);

            expect(service.getDescendantsWithoutEvent).toHaveBeenCalledWith(1, eventId);
            expect(service.getDescendantsWithoutEvent.then).toHaveBeenCalled();
            expect(service.showInheritanceConfirmationModal).not.toHaveBeenCalled();
            expect(result.data).toBe(false);
        });
    });

    it('getEventFilterMetadata should pass correct parameters', function() {
        service.getEventFilterMetadata(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/events/filterdata/-2');
    });

    it('getEvents should pass correct parameters and set eventIds', function() {
        var returnData = {
            data: [{
                eventNo: -10,
                description: 'abc'
            }, {
                eventNo: -20,
                description: 'def'
            }],
            ids: [-10, -20]
        };
        httpMock.get.returnValue = returnData;

        service.eventIds = jasmine.createSpy();
        var r = service.getEvents(-1, 1);

        expect(r).toBe(returnData);
        expect(service.eventIds).toHaveBeenCalledWith(returnData.ids);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/events', {
            params: {
                params: '1'
            }
        });
    });

    describe('maintaining event id list (for detail page navigation)', function() {
        beforeEach(function() {
            service.eventIds([-1, -2, -3]);
        });

        describe('eventIds', function() {
            it('sets and gets event id list', function() {
                expect(service.eventIds()).toEqual([-1, -2, -3]);
            });
        });

        describe('removeEventId', function() {
            it('removes event ids from list', function() {
                service.removeEventIds([{ eventNo: -1 }, { eventNo: -2 }]);

                expect(service.eventIds()).toEqual([-3]);
            });
        });

        describe('addEventId', function() {
            it('adds event id to list at specified position', function() {
                service.addEventId({ eventNo: -4 }, { eventNo: -1 });

                expect(service.eventIds()).toEqual([-1, -4, -2, -3]);
            });

            it('adds event id to last position', function() {
                service.addEventId({ eventNo: -4 });

                expect(service.eventIds()).toEqual([-1, -2, -3, -4]);
            });
        });

        describe('newly added event ids related functions', function() {
            it('should return true if the event Id exists in the newly aded event ids list', function() {
                service.addEventId({ eventNo: 1});
                service.addEventId({ eventNo: 2});
                service.addEventId({ eventNo: 3});
                expect(service.isEventNewlyAdded(3)).toBeTruthy();
            });

            it('should return false if the event Id does not exist in the newly added events list', function() {
                service.addEventId({ eventNo: 1});
                service.addEventId({ eventNo: 2});
                service.addEventId({ eventNo: 3});
                expect(service.isEventNewlyAdded(5)).toBeFalsy();
            });

            it('should reset the newly added events ids list', function() {
                service.addEventId({ eventNo: 1});
                service.addEventId({ eventNo: 2});
                service.resetNewlyAddedEventIds();

                expect(service.isEventNewlyAdded(1)).toBeFalsy();
                expect(service.isEventNewlyAdded(2)).toBeFalsy();
            });
        });
        it('should refresh event ids from the passed dataset', function() {
            service.refreshEventIds([{ eventNo: 10 }, { eventNo: 100 }]);
            expect(service.eventIds()).toEqual([10, 100]);
        });
    });

    it('searchEvents should pass correct parameters', function() {
        service.searchEvents(-1, 1);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventSearch?eventId=1');
    });

    describe('delete', function() {
        describe('confirmDeleteWorkflow', function() {
            it('opens modal for events used by cases confirmation', function() {
                service.checkEventsUsedByCases = promiseMock.createSpy([-1]);
                service.checkDescendants = promiseMock.createSpy();
                modalService.open = promiseMock.createSpy();
                service.confirmDeleteWorkflow({}, 123, [-1, 2]);

                expect(service.checkEventsUsedByCases).toHaveBeenCalledWith(123, [-1, 2]);
                expect(service.checkDescendants).toHaveBeenCalledWith({}, 123, [-1, 2]);

                var args = modalService.open.calls.first().args;
                expect(args[0]).toBe('EventsForCaseConfirmation');
                expect(args[2].items()).toEqual({ context: 'event', usedEvents: [-1], selectedCount: 2 });
            });

            it('continues if no events used by cases', function() {
                service.checkEventsUsedByCases = promiseMock.createSpy();
                service.checkDescendants = promiseMock.createSpy();

                service.confirmDeleteWorkflow({}, 123, [-1, 2]);

                expect(service.checkEventsUsedByCases).toHaveBeenCalledWith(123, [-1, 2]);
                expect(service.checkDescendants).toHaveBeenCalledWith({}, 123, [-1, 2]);
                expect(modalService.open).not.toHaveBeenCalled();
            });
        });

        describe('checkDescendants', function() {
            it('confirms delete inherited events from descendants', function() {
                service.confirmDelete = promiseMock.createSpy();
                service.confirmInheritanceDelete = promiseMock.createSpy();
                service.getDescendants = promiseMock.createSpy({ descendants: [-10, 20] });

                service.checkDescendants({}, 123, [-1, 2]);

                expect(service.getDescendants).toHaveBeenCalledWith(123, [-1, 2], true);
                expect(service.confirmInheritanceDelete).toHaveBeenCalledWith({}, 123, [-1, 2], [-10, 20]);
                expect(service.confirmDelete).not.toHaveBeenCalled();
            });

            it('confirms delete when no inherited events', function() {
                service.confirmDelete = promiseMock.createSpy();
                service.confirmInheritanceDelete = promiseMock.createSpy();
                service.getDescendants = promiseMock.createSpy({ descendants: [] });

                service.checkDescendants({}, 123, [-1, 2]);

                expect(service.getDescendants).toHaveBeenCalledWith(123, [-1, 2], true);
                expect(service.confirmDelete).toHaveBeenCalledWith([-1, 2]);
                expect(service.confirmInheritanceDelete).not.toHaveBeenCalled();
            });
        });

        describe('confirmations', function() {
            it('confirmInheritanceDelete opens modalService modal', function() {
                service.confirmInheritanceDelete({}, 123, [-1, 2], [-10, 20]);

                var args = modalService.open.calls.first().args;
                expect(args[0]).toBe('InheritanceDeleteConfirmation');
                expect(args[1]).toEqual({});
                expect(args[2].items().descendants).toEqual([-10, 20]);
                expect(args[2].items().selectedCount).toEqual(2);
            });

            it('confirmDelete opens notificationService modal', function() {
                service.confirmDelete([-1, 2]);
                expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                    message: 'workflows.maintenance.deleteConfirmationEvent.messageMultiple',
                    messageParams: {
                        count: 2
                    }
                });
            });

            it('confirmDelete with singular', function() {
                service.confirmDelete([-1]);
                expect(notificationService.confirmDelete).toHaveBeenCalled();
            });
        });

        describe('reorder', function() {
            it('confirmReorderDescendants returns null if no descendants', function() {
                service.getDescendants = promiseMock.createSpy({ descendants: [] });
                service.reorderDescendants = promiseMock.createSpy();

                service.confirmReorderDescendants(123, 1, 2, 3, 4, 5, {});
                expect(modalService.open).not.toHaveBeenCalled();
                expect(service.reorderDescendants).not.toHaveBeenCalled();
            });

            it('opens confirmation then calls reorderDescendants', function() {
                service.getDescendants = promiseMock.createSpy({ descendants: [11, 22] });
                service.reorderDescendants = promiseMock.createSpy();
                modalService.open = promiseMock.createSpy();

                service.confirmReorderDescendants(123, 1, 2, 3, 4, 5, {});

                var args = modalService.open.calls.first().args;
                expect(args[0]).toBe('InheritanceReorderConfirmation');
                expect(args[1]).toEqual({});
                expect(args[2].items()).toEqual([11, 22]);

                expect(service.reorderDescendants).toHaveBeenCalledWith(123, 1, 2, 3, 4, 5);
            });
        });

        describe('create entries for event', function() {
            it('opens modal for creating entry', function() {

                modalService.open = promiseMock.createSpy();
                service.showCreateEntryModal({}, 123, [{
                    'eventNo': 1,
                    'description': 'event 1'
                }, {
                    'eventNo': 2,
                    'description': 'event 2'
                }]);

                var selectedEvents = [{
                    'eventNo': 1,
                    'description': 'event 1'
                }, {
                    'eventNo': 2,
                    'description': 'event 2'
                }];


                var args = modalService.open.calls.first().args;
                expect(args[0]).toBe('CreateEntries');
                expect(args[2].viewData).toEqual({
                    criteriaId: 123,
                    selectedEvents: selectedEvents
                });
            });
        });

        describe('apis', function() {
            it('addEvent pass correct parameters', function() {
                service.addEvent(123, 1, 2, true);
                expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events/1?insertAfterEventId=2&applyToChildren=true');
                expect(notificationService.success).toHaveBeenCalled();
            });

            it('checkEventsUsedByCases pass correct parameters', function() {
                var eventIds = [-1, 2];
                service.checkEventsUsedByCases(123, eventIds);
                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events/usedByCases?eventIds=' + JSON.stringify(eventIds));
            });

            it('getDescendants pass correct parameters', function() {
                var eventIds = [-1, 2];
                service.getDescendants(123, eventIds, true);
                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events/descendants?eventIds=' + JSON.stringify(eventIds) + '&inheritedOnly=true');
            });

            it('deleteEvents pass correct parameters', function() {
                var eventIds = [-1, 2];
                service.deleteEvents(123, eventIds, true);
                expect(httpMock.delete).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events?eventIds=' + JSON.stringify(eventIds) + '&appliesToDescendants=true');
            });

            it('reorderEvent pass correct parameters', function() {
                service.reorderEvent(123, 1, 2, 3);
                expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events/reorder', {
                    sourceId: 1,
                    targetId: 2,
                    insertBefore: 3
                });
            });

            it('reorderDescendants pass correct parameters', function() {
                service.reorderDescendants(123, 1, 2, 3, 4, 5);
                expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/123/events/descendants/reorder', {
                    sourceId: 1,
                    targetId: 2,
                    prevTargetId: 3,
                    nextTargetId: 4,
                    insertBefore: 5
                });
            });
        });
    });
});