describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlUserAccess', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, kendoGridService, picklistService, promiseMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            kendoGridService = test.mock('kendoGridService');
            picklistService = test.mock('picklistService');
            promiseMock = test.mock('promise');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            scope = $rootScope.$new();

            var viewData = {
                canEdit: true,
                entryId: 1,
                criteriaId: 2
            };

            var topicParams = {
                topic: {
                    params: {
                        viewData: viewData
                    }
                }
            };

            var c = $componentController('ipWorkflowsEntryControlUserAccess', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                kendoGridService: kendoGridService,
                picklistService: picklistService
            }, topicParams);
            c.$onInit();
            return c;
        };
    }));

    it('should initialise the kendo grid', function() {
        var c = controller();
        expect(kendoGridBuilder.buildOptions).toHaveBeenCalledWith(scope, jasmine.any(Object));
        expect(c.gridOptions).toBeDefined();
    });

    describe('Add Role', function() {
        var c;
        beforeEach(function() {
            picklistService.openModal = promiseMock.createSpy([{
                key: -1,
                value: 'abc'
            }]);

            c = controller();
            c.gridOptions.dataSource.insert = jasmine.createSpy();
        });

        it('should open the pick list and sync selections', function() {

            c.onAddClick();

            expect(picklistService.openModal).toHaveBeenCalled();
            expect(kendoGridService.sync).toHaveBeenCalledWith(c.gridOptions, [{
                key: -1,
                value: 'abc'
            }]);
        });
    });

    describe('getTopicFormData', function() {
        it('should return added and deleted items delta', function() {
            var c = controller();
            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue([{
                key: -1,
                value: 'added',
                isAdded: true
            }, {
                key: -2,
                value: 'deleted',
                deleted: true
            }, {
                key: -3,
                value: 'What?',
                isAdded: true,
                deleted: true
            }, {
                key: -4,
                value: 'existing'
            }]);

            var result = c.topic.getFormData();

            expect(result).toEqual({
                userAccessDelta: {
                    added: [-1],
                    deleted: [-2, -3]
                }
            });
        });
    });

    describe('dirtyCheck', function() {
        it('should return dirty if added or deleted', function() {
            var c = controller();

            var data = {
                key: -1,
                isAdded: false,
                deleted: false
            };
            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue([data]);

            expect(c.topic.isDirty()).toBe(false);

            data.isAdded = true;
            data.deleted = false;
            expect(c.topic.isDirty()).toBe(true);
            
            data.isAdded = false;
            data.deleted = true;
            expect(c.topic.isDirty()).toBe(true);
        })
    });
});
