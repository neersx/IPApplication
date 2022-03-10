describe('inprotech.configuration.rules.workflows.ipWorkflowsMaintenanceEventsController', function() {
    'use strict';

    var controller, scope, kendoGridBuilder, service, sharedService, modalService,
        picklistService, notificationService, promiseMock, bus, pagerHelperService,
        timeout, bulkMenuOperationsMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks.components.notification', 'inprotech.mocks.components.grid', 'inprotech.mocks.core']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('workflowsMaintenanceEventsServiceMock');
            $provide.value('workflowsMaintenanceEventsService', service);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');
            $provide.value('BulkMenuOperations', bulkMenuOperationsMock)

            bus = $injector.get('BusMock');
            $provide.value('bus', bus);

            promiseMock = $injector.get('promiseMock');

            sharedService = {
                lastSearch: null,
                selectedEventInDetail: null
            };
            $provide.value('sharedService', sharedService);

            picklistService = {
                openModal: promiseMock.createSpy({
                    key: -1
                })
            };
            $provide.value('picklistService', picklistService);

            pagerHelperService = { getPageForId: jasmine.createSpy().and.returnValue({ page: 99, relativeRowIndex: 9 }) };
            $provide.value('pagerHelperService', pagerHelperService);
        });

        inject(function($rootScope, $controller, $timeout) {
            controller = function() {
                scope = $rootScope.$new();
                scope.$emit = jasmine.createSpy();
                timeout = $timeout;

                var c = $controller('ipWorkflowsMaintenanceEventsController', {
                    $scope: scope,
                    $timeout: timeout
                }, {
                    topic: {
                        params: {}
                    }
                });
                c.$onInit();
                return c;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise grid', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.shared.selectedEventInDetail).toBeNull();
            expect(c.eventMatches).toBeNull();
            expect(service.resetNewlyAddedEventIds).toHaveBeenCalled();
        });

        it('should initialise controller', function() {
            var c = controller();
            expect(c.shared).toBe(sharedService);
        });
    });

    describe('grid', function() {
        it('should call correct Search Service', function() {
            var c = controller();
            var queryParams = {
                something: 'a'
            };

            c.criteriaId = 123;
            c.gridOptions.read(queryParams);

            expect(service.getEvents).toHaveBeenCalledWith(123, queryParams);
        });

        it('should call correct filter API', function() {
            var c = controller();
            var column = {
                field: 'importance'
            };

            c.criteriaId = 123;
            c.gridOptions.readFilterMetadata(column);

            expect(service.getEventFilterMetadata).toHaveBeenCalledWith(123, 'importance');
        });

        it('after drop complete calls service to reorder', function() {
            var c = controller();
            var args = {
                source: {
                    eventNo: 1
                },
                target: {
                    eventNo: 2
                },
                insertBefore: 3
            };

            var returnData = {
                prevTargetId: 11,
                nextTargetId: 22
            };
            c.criteriaId = 123;
            service.reorderEvent = promiseMock.createSpy(returnData);
            service.confirmReorderDescendants = promiseMock.createSpy();

            c.gridOptions.onDropCompleted(args);

            expect(service.reorderEvent).toHaveBeenCalledWith(123, 1, 2, 3);
            expect(service.refreshEventIds).toHaveBeenCalled();
            expect(service.confirmReorderDescendants).toHaveBeenCalledWith(123, 1, 2, 11, 22, 3, scope);
        });
    });

    describe('grid load', function() {
        it('should search and scroll events automatically', function() {
            var c = controller();

            c.gridOptions.dataSource = {
                take: jasmine.createSpy().and.returnValue(10),
                page: jasmine.createSpy().and.returnValue(1)
            };

            var readFn = kendoGridBuilder.buildOptions.calls.first().args[1].read;
            var queryParams = {};
            c.shared.selectedEventInDetail = { key: 99 };
            service.searchEvents.returnValue = { data: [1] };
            readFn(queryParams);
            expect(service.getEvents).toHaveBeenCalledWith(c.criteriaId, queryParams);
            expect(service.searchEvents).toHaveBeenCalledWith(c.criteriaId, 99);
        });
    });

    describe('search for event', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.criteriaId = 123;
            c.shared.selectedEventInDetail = {
                key: 321
            };

            c.gridOptions.dataSource = {
                take: jasmine.createSpy(),
                page: jasmine.createSpy()
            };
        });

        it('calls searchEvents service with correct parameters', function() {
            service.searchEvents.returnValue = {
                data: [1, 2]
            };
            c.searchEvents();

            expect(service.searchEvents).toHaveBeenCalledWith(123, 321);
        });

        it('sets events found', function() {
            var foundEvents = [1, 2, 3];
            service.searchEvents.returnValue = {
                data: foundEvents
            };
            c.searchEvents();

            expect(c.eventMatches).toBe(foundEvents);
        });

        it('marks events as found and direct match', function() {
            c.shared.selectedEventInDetail = { key: 1 };
            var foundEvents = [1, 3];
            service.searchEvents.returnValue = {
                data: foundEvents
            };
            var gridData = [{
                eventNo: 1
            }, {
                eventNo: 2
            }, {
                eventNo: 3
            }];

            c.gridOptions.data = function() {
                return gridData;
            };

            c.searchEvents();

            expect(gridData[0].isFound).toBe(true);
            expect(gridData[1].isFound).toBe(false);
            expect(gridData[2].isFound).toBe(true);

            expect(gridData[0].isDirectMatch).toBe(true);
            expect(gridData[1].isDirectMatch).toBe(false);
            expect(gridData[2].isDirectMatch).toBe(false);

            expect(c.eventMatches).toBe(foundEvents);
        });

        it('marks direct match events', function() {
            var foundEvents = [1, 3];
            service.searchEvents.returnValue = {
                data: foundEvents
            };
            var gridData = [{
                eventNo: 1
            }, {
                eventNo: 2
            }, {
                eventNo: 3
            }];

            c.gridOptions.data = function() {
                return gridData;
            };

            c.searchEvents();

            expect(gridData[0].isFound).toBe(true);
            expect(gridData[1].isFound).toBe(false);
            expect(gridData[2].isFound).toBe(true);
            expect(c.eventMatches).toBe(foundEvents);
        });

        it('unmarks events not found', function() {
            var foundEvents = [1];
            service.searchEvents.returnValue = {
                data: foundEvents
            };
            var gridData = [{
                eventNo: 1
            }, {
                eventNo: 2,
                isFound: true
            }];

            c.gridOptions.data = function() {
                return gridData;
            };

            c.searchEvents();

            expect(gridData[0].isFound).toBe(true);
            expect(gridData[1].isFound).toBe(false);
            expect(c.eventMatches).toBe(foundEvents);
        });

        it('unmarks all if no event', function() {
            var gridData = [{
                eventNo: 1,
                isFound: true
            }, {
                eventNo: 2,
                isFound: true
            }];

            c.gridOptions.data = function() {
                return gridData;
            };
            c.shared.selectedEventInDetail = {
                key: ''
            };

            c.searchEvents();

            expect(gridData[0].isFound).toBe(false);
            expect(gridData[1].isFound).toBe(false);
            expect(c.eventMatches).toBe(null);
        });

        it('scrolls to direct match', function() {
            service.searchEvents.returnValue = {
                data: [1, 2]
            };
            var allEventIds = [1, 2, 3];
            service.eventIds.returnValue = allEventIds;

            pagerHelperService.getPageForId.and.returnValue({ page: 1, relativeRowIndex: 2 });

            c.searchEvents(true);
            expect(pagerHelperService.getPageForId.calls.count()).toBe(1);
            expect(bus.channel).toHaveBeenCalledWith('grid.eventResults');
        });

        it('scrolls to first indirect match if no direct match', function() {
            service.searchEvents.returnValue = {
                data: [1, 2]
            };
            var allEventIds = [1, 2, 3];
            service.eventIds.returnValue = allEventIds;

            pagerHelperService.getPageForId.and.returnValues({ page: -1, relativeRowIndex: -1 }, { page: 2, relativeRowIndex: 3 });

            c.searchEvents(true);
            expect(pagerHelperService.getPageForId.calls.count()).toBe(2);
            expect(bus.channel).toHaveBeenCalledWith('grid.eventResults');
        });
    });

    describe('click add event directly to criteria button', function() {
        var c;
        beforeEach(function() {
            c = controller();

            c.criteriaId = 123;
            c.gridOptions = {
                data: function() {
                    return [{
                        eventNo: 111,
                        inherit: true
                    }];
                },
                dataSource: {
                    add: jasmine.createSpy(),
                    insert: jasmine.createSpy()
                },
                getSelectedRow: jasmine.createSpy(),
                selectRowByIndex: jasmine.createSpy()
            };

            service.addEventWorkflow = promiseMock.createSpy(true);
            service.addEvent = promiseMock.createSpy({});
        });

        it('adds event directly should success', function() {
            c.shared.selectedEventInDetail = {
                key: 222
            };

            c.addEventDirectly();

            expect(c.gridOptions.getSelectedRow).toHaveBeenCalled();
        });

        it('adds event directly should success, even for key event no 0', function() {
            c.shared.selectedEventInDetail = {
                key: 0
            };

            c.addEventDirectly();

            expect(c.gridOptions.getSelectedRow).toHaveBeenCalled();
        });

        it('adds event directly none selected should fail', function() {
            c.shared.selectedEventInDetail = {
                key: ''
            };

            c.addEventDirectly();
            expect(service.addEventWorkflow).not.toHaveBeenCalled();
        });

    });

    describe('canAddEventDirectly method', function() {
        it('should show if can edit', function() {
            var c = controller();

            c.canEdit = false;
            c.shared.selectedEventInDetail = {
                key: 1
            };

            var result = c.canAddEventDirectly();
            expect(result).toEqual(false);

            c.canEdit = true;
            result = c.canAddEventDirectly();
            expect(result).toEqual(true);
        });

        it('should show if event does not exist', function() {
            var c = controller();

            c.canEdit = true;
            c.shared.selectedEventInDetail = {
                key: 1
            };
            var result = c.canAddEventDirectly();
            expect(result).toEqual(true);

            service.eventIds.returnValue = [1]
            result = c.canAddEventDirectly();
            expect(result).toEqual(false);
        });
    });

    describe('click add event button', function() {
        var c;
        beforeEach(function() {
            c = controller();

            c.criteriaId = 123;
            c.gridOptions = {
                data: function() {
                    return [{
                        eventNo: 111,
                        inherit: true
                    }];
                },
                dataSource: {
                    add: jasmine.createSpy(),
                    insert: jasmine.createSpy()
                },
                getSelectedRow: jasmine.createSpy(),
                selectRowByIndex: jasmine.createSpy()
            };

            picklistService.openModal = promiseMock.createSpy({
                key: 222
            });
            service.addEventWorkflow = promiseMock.createSpy(true);
            service.addEvent = promiseMock.createSpy({});
        });

        it('should pop up event picklistService', function() {
            c.onClickAdd();
            expect(picklistService.openModal).toHaveBeenCalledWith(scope, {
                type: 'events',
                canMaintain: true,
                searchValue: null,
                size: 'xl',
                columnMenu: true,
                displayName: 'picklist.event.Type'
            });
        });

        it('checks if selected event exists', function() {
            picklistService.openModal = promiseMock.createSpy({
                key: 111
            });
            service.eventIds.returnValue = [111];

            c.onClickAdd();
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('adds event', function() {
            var addedEvent = {
                eventNo: 222,
                inherit: true
            };
            service.addEvent = promiseMock.createSpy(addedEvent);
            service.eventIds.returnValue = [];

            c.onClickAdd();

            expect(c.gridOptions.getSelectedRow).toHaveBeenCalled();
            expect(service.addEventWorkflow).toHaveBeenCalledWith(123, 222, scope);
            expect(service.addEventId).toHaveBeenCalledWith(addedEvent, undefined);
            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
        });

        it('marks newly added events', function() {
            service.isEventNewlyAdded = jasmine.createSpy().and.returnValues(true, false);

            var result = c.prepareDataSource({ data: [{ eventNo: 10 }, { eventNo: 99 }] });

            expect(result.data[0].added).toBeTruthy();
            expect(result.data[0].id).toBe(10);
            expect(result.data[1].added).toBeUndefined();
            expect(result.data[1].id).toBe(99);
        });

        it('inserts event after selected row', function() {
            var selected = c.gridOptions.data()[0];
            c.gridOptions.getSelectedRow = jasmine.createSpy().and.returnValue(selected);
            c.gridOptions.dataSource.indexOf = jasmine.createSpy().and.returnValue(0);
            var addedEvent = {
                eventNo: 222,
                inherit: true
            };
            service.addEvent = promiseMock.createSpy(addedEvent);
            service.eventIds.returnValue = [];

            c.onClickAdd();

            expect(c.gridOptions.getSelectedRow).toHaveBeenCalled();
            expect(service.addEvent).toHaveBeenCalledWith(123, 222, 111, true);
            expect(addedEvent.added).toBe(true);
            expect(service.addEventId).toHaveBeenCalledWith(addedEvent, selected);
            expect(bus.channel).toHaveBeenCalledWith('gridRefresh.eventResults');
        });

        it('invokes scroll to matched events', function() {
            var addedEvent = {};
            service.addEvent = promiseMock.createSpy(addedEvent);
            service.eventIds.returnValue = [];
            c.shared.selectedEventInDetail = {};
            c.gridOptions.dataSource = {
                take: jasmine.createSpy(),
                page: jasmine.createSpy()
            };
            c.onClickAdd();
            timeout.flush();
            expect(pagerHelperService.getPageForId).toHaveBeenCalled();
        });

        it('automatically populates event description when no matches', function() {
            c.shared.selectedEventInDetail = {
                key: -1,
                value: 'abc'
            };
            service.eventIds.returnValue = [999];
            c.canEdit = true;

            c.onClickAdd();
            expect(picklistService.openModal).toHaveBeenCalledWith(scope, {
                type: 'events',
                canMaintain: true,
                searchValue: 'abc',
                size: 'xl',
                columnMenu: true,
                displayName: 'picklist.event.Type'
            });

            service.eventIds.returnValue = [-1];
            c.onClickAdd();
            expect(picklistService.openModal).toHaveBeenCalledWith(scope, {
                type: 'events',
                canMaintain: true,
                searchValue: null,
                size: 'xl',
                columnMenu: true,
                displayName: 'picklist.event.Type'
            });
        });
    });

    describe('click delete', function() {
        var c, rows;
        beforeEach(function() {
            c = controller();

            rows = [{
                id: 1,
                eventNo: 1,
                selected: true
            }, {
                id: 2,
                eventNo: 2,
                selected: true
            }, {
                eventNo: 3
            }];

            c.criteriaId = 123;
            c.gridOptions = {
                dataSource: {
                    data: function() {
                        return rows;
                },
                    _total: 1
                },
                data: function() {
                    return rows;
                },
                removeDeletedRows: jasmine.createSpy()
            };

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([rows[0], rows[1]]);

            spyOn(c.gridOptions.dataSource, 'data').and.callThrough();
            service.confirmDeleteWorkflow = promiseMock.createSpy({
                applyToDescendants: true
            });
            service.deleteEvents = promiseMock.createSpy();
        });

        it('should confirm then delete selected events', function() {
            c.menu.items[0].click(true);

            expect(service.confirmDeleteWorkflow).toHaveBeenCalledWith(scope, 123, [1, 2]);
            expect(service.deleteEvents).toHaveBeenCalledWith(123, [1, 2], true);
            expect(notificationService.success).toHaveBeenCalled();

            expect(service.removeEventIds).toHaveBeenCalledWith([rows[0], rows[1]]);
        });

        it('should remove rows from grid', function() {
            c.menu.items[0].click();

            expect(rows[0].deleted).toBe(true);
            expect(rows[1].deleted).toBe(true);
            expect(c.gridOptions.removeDeletedRows).toHaveBeenCalled();
        });

        it('should remove deleted events from event matches', function() {
            c.eventMatches = [1, 2, 3]
            c.menu.items[0].click();

            expect(c.eventMatches).toEqual([3]);
        });
        it('should emit topic item numbers count', function() {
            c.topic.key = "events topic";
            c.topic.isSubSection = false;

            c.menu.items[0].click();

            var expectedData = {
                isSubSection: c.topic.isSubSection,
                key: c.topic.key,
                total: c.gridOptions.dataSource._total
            };
            expect(scope.$emit).toHaveBeenCalledWith('topicItemNumbers', expectedData);
    });
    });

    describe('on click create entry', function() {
        var c;
        beforeEach(function() {
            c = controller();

            c.criteriaId = 123;
            c.gridOptions = {
                data: function() {
                    return [{
                        eventNo: -1
                    }, {
                        eventNo: -2
                    }];
                }
            };
        });

        it('should open create entry dialog with selected events', function() {
            var c = controller();

            var rows = [{
                eventNo: 1,
                selected: true,
                description: 'event 1'
            }, {
                eventNo: 2,
                selected: true,
                description: 'event 2'
            }, {
                eventNo: 3
            }];

            c.criteriaId = 123;
            c.gridOptions = {
                dataSource: {
                    data: function() {
                        return {
                            toJSON: function() {
                                return rows;
                            }
                        };
                    }
                },
                data: function() {
                    return rows;
                }
            };
            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([rows[0], rows[1]]);
            spyOn(c.gridOptions.dataSource, 'data').and.callThrough();

            service.showCreateEntryModal = promiseMock.createSpy();

            c.menu.items[1].click();

            expect(service.showCreateEntryModal).toHaveBeenCalledWith(scope, 123, [{
                'eventNo': 1,
                'description': 'event 1'
            }, {
                'eventNo': 2,
                'description': 'event 2'
            }]);
        });
    });
});