describe('inprotech.configuration.rules.workflows.ipWorkflowsMaintenanceEntriesController', function() {
    'use strict';

    var controller, httpMock, scope, kendoGridBuilder, service, sharedService, modalService, promiseMock, notificationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks.components.grid']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('workflowsMaintenanceEntriesServiceMock');
            $provide.value('workflowsMaintenanceEntriesService', service);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            promiseMock = $injector.get('promiseMock');

            notificationService = test.mock('notificationService');
        });
    });

    beforeEach(inject(function($rootScope, $controller) {
        controller = function() {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            sharedService = {
                lastSearch: null
            };
            var c = $controller('ipWorkflowsMaintenanceEntriesController', {
                $scope: scope,
                sharedService: sharedService
            }, {
                topic: {
                    params: {}
                }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function() {
        it('should initialise grid', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
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

            expect(service.getEntries).toHaveBeenCalledWith(123, queryParams);
        });

        var dropArgs = {
            source: {
                entryNo: 1
            },
            target: {
                entryNo: 2
            },
            insertBefore: true
        };
        it('after drop complete calls service to reorder', function() {
            var c = controller();
            var args = angular.copy(dropArgs);

            var returnData = {
                prevTargetId: 11,
                nextTargetId: 22,
                descendents: null
            };
            c.criteriaId = 123;
            service.reorderEntry = promiseMock.createSpy(returnData);
            service.reorderDescendantsEntry = promiseMock.createSpy();

            c.gridOptions.onDropCompleted(args);

            expect(service.reorderEntry).toHaveBeenCalledWith(123, 1, 2, true);
            expect(args.source.added).toBe(true);
            expect(modalService.open).not.toHaveBeenCalled();
            expect(service.reorderDescendantsEntry).not.toHaveBeenCalled();
        });

        it('after drop completes display confirmation, if descendents are present', function() {
            var c = controller();
            var args = angular.copy(dropArgs);
            var descendents = [{
                id: 1,
                description: 'A'
            }, {
                id: 2,
                description: 'B'
            }];

            var returnData = {
                prevTargetId: 11,
                nextTargetId: 22,
                descendents: descendents
            };

            c.criteriaId = 123;
            service.reorderEntry = promiseMock.createSpy(returnData);
            service.reorderDescendantsEntry = promiseMock.createSpy();
            modalService.open = promiseMock.createSpy(true);

            c.gridOptions.onDropCompleted(args);

            var modalArgs = modalService.open.calls.first().args;
            expect(modalArgs[0]).toBe('InheritanceReorderConfirmation');
            expect(modalArgs[2].items()).toEqual(descendents);
            expect(service.reorderDescendantsEntry).toHaveBeenCalledWith(123, 1, 2, 11, 22, true);
        });
    });

    describe('search for entry with event', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.criteriaId = 123;
            c.shared.selectedEventInDetail = {
                key: 321
            };
        });

        it('calls searchEntryEvents service with correct parameters', function() {
            service.searchEntryEvents.returnValue = {
                data: [1, 2]
            };
            c.searchEntryEvents();

            expect(service.searchEntryEvents).toHaveBeenCalledWith(123, 321);
        });

        it('sets entries found count', function() {
            service.searchEntryEvents.returnValue = {
                data: [1, 2, 3]
            };
            c.searchEntryEvents();

            expect(c.entryCount).toBe(3);
        });

        it('marks entries as found', function() {
            service.searchEntryEvents.returnValue = {
                data: [1, 3]
            };
            var gridData = [{
                entryNo: 1
            }, {
                entryNo: 2
            }, {
                entryNo: 3
            }];

            c.gridOptions.data = function() {
                return gridData;
            };

            c.searchEntryEvents();

            expect(gridData[0].isFound).toBe(true);
            expect(gridData[1].isFound).toBe(false);
            expect(gridData[2].isFound).toBe(true);
            expect(c.entryCount).toBe(2);
        });

        it('unmarks entries not found', function() {
            service.searchEntryEvents.returnValue = {
                data: [1]
            };
            var gridData = [{
                entryNo: 1
            }, {
                entryNo: 2,
                isFound: true
            }];

            c.gridOptions.data = function() {
                return gridData;
            };

            c.searchEntryEvents();

            expect(gridData[0].isFound).toBe(true);
            expect(gridData[1].isFound).toBe(false);
            expect(c.entryCount).toBe(1);
        });

        it('unmarks all if no event', function() {
            var gridData = [{
                entryNo: 1,
                isFound: true
            }, {
                entryNo: 2,
                isFound: true
            }];

            c.gridOptions.data = function() {
                return gridData;
            };
            c.shared.selectedEventInDetail = {
                key: ''
            };

            c.searchEntryEvents();

            expect(gridData[0].isFound).toBe(false);
            expect(gridData[1].isFound).toBe(false);
            expect(c.entryCount).toBe(null);
        });

        it('unmarks all on error', function() {

            service.searchEntryEvents.returnValue = {
                data: [1, 2]
            };

            var gridData = [{
                entryNo: 1,
                isFound: true
            }, {
                entryNo: 2,
                isFound: true
            }];
            c.gridOptions.data = function() {
                return gridData;
            };

            scope.vm = {
                form: {
                    event: {
                        $invalid: true
                    }
                }
            };

            scope.$digest();

            expect(gridData[0].isFound).toBe(false);
            expect(gridData[1].isFound).toBe(false);
            expect(c.entryCount).toBe(null);
        });
    });

    describe('on click prepareToGoEntryControl', function() {
        var c;
        beforeEach(function() {
            c = controller();

            c.criteriaId = 123;
            c.gridOptions = {
                data: function() {
                    return [{
                        entryNo: -1
                    }, {
                        entryNo: -2
                    }];
                }
            };
        });

        it('should call entryIds with grid data', function() {
            c.prepareToGoEntryControl(-1);

            expect(service.entryIds).toHaveBeenCalledWith(c.gridOptions.data());
        });
    });

    describe('delete', function() {
        it('should confirm, delete selected entries then remove from grid', function() {
            var c = controller();

            c.topic.key = 'newTopic';
            c.topic.isSubSection = false;

            var rows = [{
                id: 1,
                entryNo: 1,
                selected: true
            }, {
                id: 2,
                entryNo: 2,
                selected: true
            }, {
                id: 3,
                entryNo: 3
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
                    },
                    _total: 1
                },
                data: function() {
                    return rows;
                }
            };
            spyOn(c.gridOptions.dataSource, 'data').and.callThrough();

            service.confirmDeleteWorkflow = promiseMock.createSpy({
                applyToDescendants: true
            });
            service.deleteEntries = promiseMock.createSpy();

            c.menu.items[0].click();

            expect(service.confirmDeleteWorkflow).toHaveBeenCalledWith(scope, 123, [1, 2]);
            expect(service.deleteEntries).toHaveBeenCalledWith(123, [1, 2], true);
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.dataSource.data).toHaveBeenCalledWith([{
                id: 3,
                entryNo: 3
            }]);
            var expectedData = {
                isSubSection: c.topic.isSubSection,
                key: c.topic.key,
                total: c.gridOptions.dataSource._total
            };
            expect(scope.$emit).toHaveBeenCalledWith('topicItemNumbers', expectedData);
        });
    });
});