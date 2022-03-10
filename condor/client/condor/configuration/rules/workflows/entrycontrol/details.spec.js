describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlDetails', function () {
    'use strict';

    var controller, kendoGridBuilder, service, viewData, extObjFactory, topic, modalService, promiseMock, scope;

    beforeEach(function () {
        module('inprotech.configuration.rules.workflows');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.grid', 'inprotech.mocks.configuration.rules.workflows', 'inprotech.core.extensible']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('workflowsEntryControlServiceMock');
            $provide.value('workflowsEntryControlService', service);

            extObjFactory = $injector.get('ExtObjFactory');
            promiseMock = test.mock('promise');
        });
    });

    beforeEach(inject(function ($rootScope, $componentController) {
        controller = function (data) {
            scope = $rootScope.$new();
            viewData = {
                canEdit: true,
                entryId: 1,
                criteriaId: 2,
                isInherited: true,
                parent: {
                    atLeastOneEventFlag: 'a',
                    policeImmediately: 'b',
                    officialNumberType: 'c',
                    fileLocation: 'd'
                }
            };
            _.extend(viewData, data);
            topic = {
                params: {
                    viewData: viewData
                }
            };
            modalService = {
                openModal: promiseMock.createSpy()
            };

            var c = $componentController('ipWorkflowsEntryControlDetails', {
                $scope: scope,
                ExtObjFactory: extObjFactory,
                modalService: modalService
            }, {
                topic: topic
            });
            c.$onInit();

            c.gridOptions.dataSource = {
                data: _.constant([])
            };            
            return c;
        };
    }));

    describe('initialise controller', function () {
        it('should initialise variables correctly', function () {
            var c = controller();

            expect(c.canEdit).toEqual(true);
            expect(c.formData.entryId).toBe(1);
            expect(c.topic.initialised).toEqual(true);

            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();

            expect(c.parentData.atLeastOneEventFlag).toEqual('a');
            expect(c.parentData.policeImmediately).toEqual('b');
            expect(c.parentData.officialNumberType).toEqual('c');
            expect(c.parentData.fileLocation).toEqual('d');
        });
    });

    describe('UI', function () {
        it('fieldClasses should build ng-class', function () {
            var c = controller();
            var r = c.fieldClasses('officialNumberType');
            expect(r).toBe('{edited: vm.formData.isDirty(\'officialNumberType\')}');
        });
    });

    describe('maintenance', function () {
        var ctrl, newData, dataItem, expectedOptions;
        beforeEach(function () {
            ctrl = controller({
                criteriaId: 99,
                entryId: -11,
                description: 'Entry'
            });
            ctrl.gridOptions = {
                dataSource: {
                    insert: jasmine.createSpy()
                },
                insertAfterSelectedRow: jasmine.createSpy()
            };
            ctrl.gridOptions.dataSource.data = _.constant([{
                entryEvent: {
                    key: 1,
                    value: 'Event1'
                }
            }]);

            dataItem = {
                entryEvent: {
                    key: 1,
                    value: 'Event1'
                }
            };
            newData = {
                entryEvent: {
                    key: 10,
                    value: 'Event10'
                }
            };

            modalService.openModal = promiseMock.createSpy(newData);

            expectedOptions = {
                criteriaId: 99,
                entryId: -11,
                entryDescription: 'Entry',
                all: ctrl.gridOptions.dataSource.data()
            };
        });

        describe('onAddClick', function () {
            it('opens modal for maintenance', function () {
                ctrl.onAddClick();

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'EntryEventMaintenance',
                        mode: 'add'
                    }, expectedOptions)));
            });

            it('then inserts data at last position', function () {
                ctrl.onAddClick();

                expect(ctrl.gridOptions.insertAfterSelectedRow).toHaveBeenCalledWith(newData);
            });
        });

        describe('onEditClick', function () {
            it('opens modal for maintenance', function () {
                ctrl.onEditClick(dataItem);

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'EntryEventMaintenance',
                        mode: 'edit',
                        dataItem: dataItem
                    }, expectedOptions)));
            });
        });
    });

    describe('getFormData', function () {
        it('should include other details', function () {
            var data = {
                officialNumberType: {
                    key: 1
                },
                fileLocation: {
                    key: 'test'
                },
                policeImmediately: false,
                atLeastOneEventFlag: true
            }
            var c = controller(data);

            var result = c.topic.getFormData();
            expect(result.officialNumberTypeId).toEqual(1);
            expect(result.fileLocationId).toEqual('test');
            expect(result.shouldPoliceImmediate).toEqual(false);
            expect(result.atLeastOneFlag).toEqual(true);
        });

        it('should include added and updated events', function () {
            var addedEvents = [{
                entryEvent: {
                    key: 1,
                    value: 'event1'
                },
                eventDate: 0,
                overrideEventDate: 1,
                isAdded: true
            }, {
                entryEvent: {
                    key: 2,
                    value: 'event2'
                },
                dueDate: 1,
                isAdded: true
            }, {
                entryEvent: {
                    key: 3,
                    value: 'event3'
                },
                policing: 2,
                dueDateResp: 3,
                overrideDueDate: 1,
                overrideEventDate: 0,
                isEdited: true
            }, {
                entryEvent: {
                    key: 13,
                    value: 'event13'
                }
            }];

            var c = controller();
            c.gridOptions.getRelativeItemAbove = jasmine.createSpy().and.returnValue(null);

            c.gridOptions.dataSource.data = _.constant(addedEvents);
            var result = c.topic.getFormData();
            expect(result.entryEventDelta).toBeDefined();
            expect(result.entryEventDelta.added).toBeDefined();
            expect(result.entryEventDelta.added.length).toBe(2);
            expect(result.entryEventDelta.updated).toBeDefined();
            expect(result.entryEventDelta.updated.length).toBe(1);

            expect(result.entryEventDelta.added[0].eventId).toBe(1);
            expect(result.entryEventDelta.added[0].eventAttribute).toBe(0);
            expect(result.entryEventDelta.added[0].overrideEventAttribute).toBe(1);

            expect(result.entryEventDelta.added[1].eventId).toBe(2);
            expect(result.entryEventDelta.added[1].dueAttribute).toBe(1);

            expect(result.entryEventDelta.updated[0].eventId).toBe(3);
            expect(result.entryEventDelta.updated[0].policingAttribute).toBe(2);
            expect(result.entryEventDelta.updated[0].dueDateResponsibleNameAttribute).toBe(3);
            expect(result.entryEventDelta.updated[0].overrideDueAttribute).toBe(1);
            expect(result.entryEventDelta.updated[0].overrideEventAttribute).toBe(0);
        });

        it('should add relativeEventId for added events', function () {
            var events = [{
                entryEvent: {
                    key: 1,
                    value: 'event1'
                },
                eventDate: 0
            }, {
                entryEvent: {
                    key: 2,
                    value: 'event2'
                },
                isAdded: true
            }, {
                entryEvent: {
                    key: 3,
                    value: 'event3'
                }
            }];

            var c = controller();
            c.gridOptions.getRelativeItemAbove = jasmine.createSpy().and.returnValue(events[0]);
            c.gridOptions.dataSource.data = _.constant(events);
            var result = c.topic.getFormData();
            expect(result.entryEventDelta.added[0].relativeEventId).toBe(1);
        });

        it('should set flag for reorder when dropped', function () {
            var c = controller();

            var args = {
                source: {},
                target: {},
                insertBefore: true
            };

            c.gridOptions.onDropCompleted(args);
            expect(args.source.moved).toBe(true);
        });

        it('should send moved items along with relative events for saving', function () {
            var events = [{
                entryEvent: {
                    key: 1,
                    value: 'event1'
                }
            }, {
                entryEvent: {
                    key: 2,
                    value: 'event2'
                },
                moved: true
            }];

            var c = controller();
            c.gridOptions.getRelativeItemAbove = jasmine.createSpy().and.returnValue(events[0]);
            c.gridOptions.dataSource.data = _.constant(events);
            var result = c.topic.getFormData();
            expect(result.entryEventsMoved[0].prevEventId).toBe(1);
            expect(result.entryEventsMoved[0].eventId).toBe(2);
        });
    });

    describe('setError', function () {
        it('should set error on event row', function () {
            var events = [{
                entryEvent: {
                    key: 1
                }
            }, {
                entryEvent: {
                    key: 2
                }
            }, {
                entryEvent: {
                    key: 3
                }
            }];

            var c = controller();

            c.gridOptions.dataSource.data = _.constant(events);
            c.topic.setError([{
                field: 'entryEvents',
                id: 1
            }]);
            c.topic.setError([{
                field: 'entryEvents',
                id: 3
            }]);

            expect(events[0].error).toBeTruthy();
            expect(events[2].error).toBeTruthy();
        });
    });

    describe('state management', function () {
        var attachSpy, isDirtySpy, saveSpy, isDirtyReturn;
        beforeEach(function () {
            isDirtyReturn = true;
            attachSpy = jasmine.createSpy().and.returnValue(viewData);
            isDirtySpy = jasmine.createSpy().and.callFake(function () {
                return isDirtyReturn;
            });
            saveSpy = jasmine.createSpy().and.returnValue('s');

            var contextMock = {
                createContext: function () {
                    return {
                        attach: attachSpy,
                        isDirty: isDirtySpy,
                        save: saveSpy
                    }
                }
            };
            spyOn(extObjFactory.prototype, 'useDefaults').and.returnValue(contextMock);
        });

        it('attaches state observer', function () {
            controller();
            expect(attachSpy).toHaveBeenCalledWith(viewData);
        });

        it('returns dirty state from isDirty', function () {
            var c = controller();
            var result = c.topic.isDirty();
            expect(isDirtySpy).toHaveBeenCalled();
            expect(result).toBe(true);
        });

        it('returns dirty from isDirty, if event is added', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {}
            };
            c.gridOptions.dataSource.data = _.constant([{
                isAdded: true
            }]);
            var result = c.topic.isDirty();
            expect(result).toBeTruthy();
        });

        it('returns errorous if event grid contains error', function () {
            var c = controller();
            c.form = {
                $invalid: false
            };

            c.gridOptions.dataSource.data = _.constant([{
                error: true
            }]);

            var result = c.topic.hasError();
            expect(result).toBeTruthy();
        });

        it('hasError should only return true if invalid and dirty', function () {
            var c = controller();
            expect(dirtyCheck(c, true)).toBe(true);
            expect(dirtyCheck(c, false)).toBe(false);

            isDirtyReturn = false;
            expect(dirtyCheck(c, true)).toBe(false);
            expect(dirtyCheck(c, false)).toBe(false);
        });

        function dirtyCheck(c, invalid) {
            c.form = {
                $invalid: invalid
            };
            return c.topic.hasError();
        }
    });
});
