describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlSatisfyingEvents', function() {
    'use strict';

    var controller, kendoGridBuilder, kendoGridService, service;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            service = test.mock('workflowsEventControlService');
            kendoGridBuilder = test.mock('kendoGridBuilder');
            kendoGridService = test.mock('kendoGridService');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        eventId: -222,
                        canEdit: true
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlSatisfyingEvents', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                workflowsEventControlService: service
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.criteriaId).toEqual(-111);
            expect(c.eventId).toEqual(-222);
            expect(c.canEdit).toEqual(true);
            expect(c.formatPicklistColumn).toBeDefined();
            expect(c.gridOptions).toBeDefined();
            expect(c.relativeCycles).toBeDefined();
            expect(c.displayRelativeCycle).toBeDefined();
            expect(c.onAddClick).toBeDefined();
            expect(c.onEventChanged).toBeDefined();
            expect(c.eventPicklistScope).toBeDefined();
            expect(c.onCycleChanged).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
        });
    });

    describe('On Add Click', function() {
        it('should add an item to the end of the grid', function() {
            var c = controller();
            var totalSpy = jasmine.createSpy().and.returnValue(99);
            c.gridOptions.dataSource = {
                total: totalSpy
            };
            c.form = {
                '$invalid': false
            };

            c.onAddClick();
            expect(c.gridOptions.insertRow).toHaveBeenCalledWith(99, jasmine.objectContaining({
                added: true
            }));
        });
    });

    describe('topic state methods', function() {
        it('should return form data', function() {
            var c = controller();
            var delta = {
                added: 1
            };
            service.mapGridDelta = jasmine.createSpy().and.returnValue(delta);

            var result = c.topic.getFormData();

            expect(service.mapGridDelta).toHaveBeenCalled();
            expect(result).toEqual({
                satisfyingEventsDelta: delta
            });
        });

        it('should indicate errors on the form', function() {
            var c = controller();
            c.form = {
                '$invalid': true
            };
            expect(c.topic.hasError()).toBe(true);
            c.form.$invalid = false;
            expect(c.topic.hasError()).toBe(false);
        });

        it('should indicate changes on the form', function() {
            var c = controller();
            kendoGridService.isGridDirty.returnValue = false;
            c.form = {
                '$dirty': true
            };
            expect(c.topic.isDirty()).toBe(true);

            c.form.$dirty = false;
            expect(c.topic.isDirty()).toBe(false);

            kendoGridService.isGridDirty.returnValue = true;
            expect(c.topic.isDirty()).toBe(true);
        });
    });

    describe('on row edit', function() {
        var rowForm;
        beforeEach(function() {
            rowForm = {
                event: {
                    '$setValidity': jasmine.createSpy()
                },
                relativeCycle: {
                    '$setValidity': jasmine.createSpy()
                }
            };
        });

        it('marks rows as isEdited', function() {
            var c = controller();

            var item = {};

            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue([item]);

            c.onEventChanged(item, rowForm);
            expect(item.isEdited).toBe(true);
        });

        it('checks for duplicate events', function() {
            var c = controller();
            var item = {
                'b': 'b',
                'satisfyingEvent': {
                    'maxCycles': 1
                }
            };
            var allItems = {
                'b': 'b'
            };
            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue(allItems);

            service.isDuplicated = jasmine.createSpy().and.returnValue(true);

            c.onEventChanged(item, rowForm);

            expect(service.isDuplicated).toHaveBeenCalledWith(jasmine.anything(), item, ['satisfyingEvent']);
            expect(rowForm.event.$setValidity).toHaveBeenCalledWith('duplicate', false);
        });

        it('checks for duplicate cycle', function() {
            var c = controller();
            var item = {
                'b': 'b',
                'relativeCycle': 1,
                'satisfyingEvent': {
                    'maxCycles': 9999,
                    'key': 111
                }
            };
            var allItems = [{
                    'b': 'b',
                    'relativeCycle': 1,
                    'satisfyingEvent': {
                        'key': 111
                    }
                },
                {
                    'b': 'b',
                    'relativeCycle': 1,
                    'satisfyingEvent': {
                        'key': 111
                    }
                },
                {
                    'c': 'c',
                    'relativeCycle': 1,
                    'satisfyingEvent': {
                        'key': 112
                    }
                }
            ];
            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue(allItems);

            service.isDuplicated = jasmine.createSpy().and.returnValue(true);

            c.onCycleChanged(item, rowForm);

            expect(service.isDuplicated).toHaveBeenCalledWith(jasmine.anything(), item, ['satisfyingEvent']);
            expect(rowForm.relativeCycle.$setValidity).toHaveBeenCalledWith('duplicate', false);
        });

        it('defaults relative cycle', function() {
            var c = controller();

            var item = {
                'satisfyingEvent': {
                    maxCycles: 1
                }
            };

            c.onEventChanged(item, rowForm);
            expect(item.relativeCycle).toBe(3);

            item.satisfyingEvent.maxCycles = 2;
            c.onEventChanged(item, rowForm);
            expect(item.relativeCycle).toBe(0);
        });
    });
});