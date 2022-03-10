describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlEventsToClear', function() {
    'use strict';

    var controller, kendoGridBuilder, service;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            service = test.mock('workflowsEventControlService');
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
            var c = $componentController('ipWorkflowsEventControlEventsToClear', {
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

    it('init', function() {
        var c = controller();

        expect(c.criteriaId).toEqual(-111);
        expect(c.eventId).toEqual(-222);
    });

    it('onAddClick', function() {
        var c = controller();

        c.gridOptions.dataSource.total = _.constant(10);
        c.onAddClick();

        expect(c.gridOptions.insertRow).toHaveBeenCalledWith(10, jasmine.any(Object));
    });

    it('hasError', function() {
        var c = controller();

        c.form = {
            $invalid: true
        };

        expect(c.topic.hasError()).toBe(true);

        c.form = {
            $invalid: false
        };

        c.gridOptions.dataSource.data = _.constant([]);

        expect(c.topic.hasError()).toBe(false);
    });

    it('isDirty', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            added: true
        }]);
        expect(c.topic.isDirty()).toBe(true);
    });

    it('validateClearingCheckbox', function() {
        var c = controller();
        expect(c.onCheckboxChange({
            error: _.noop
        })).toBe(false);

        expect(c.onCheckboxChange({
            clearEventOnEventChange: true,
            error: _.noop
        })).toBe(true);
    });

    it('getFormData', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            added: true,
            sequence: 1,
            eventToClear: {
                key: 2
            },
            relativeCycle: 3,
            clearEventOnEventChange: true,
            clearDueDateOnEventChange: true,
            clearEventOnDueDateChange: true,
            clearDueDateOnDueDateChange: true
        }]);

        var r = c.topic.getFormData();

        expect(r).toEqual({
            eventsToClearDelta: {
                added: [{
                    sequence: 1,
                    eventToClearId: 2,
                    relativeCycle: 3,
                    clearEventOnEventChange: true,
                    clearDueDateOnEventChange: true,
                    clearEventOnDueDateChange: true,
                    clearDueDateOnDueDateChange: true
                }],
                deleted: [],
                updated: []
            }
        });
    });

    it('onEventChanged', function() {
        var c = controller();
        service.isDuplicated = _.constant(false);
        var obj = {
            error: _.noop,
            eventToClear: {
                maxCycles: 1
            }
        };

        c.onEventChanged(obj);

        expect(obj.relativeCycle).toBe(3);
    });

    it('should check the event date checkbox, when no checkbox changed and event is picked', function() {
        var c = controller();
        c.onCheckboxChange = jasmine.createSpy();
        service.isDuplicated = _.constant(false);
        var obj = {
            error: _.noop,
            eventToClear: {},
            clearDueDateOnDueDateChange: false,
            clearDueDateOnEventChange: false,
            clearEventOnDueDateChange: false,
            clearEventOnEventChange: false
        };

        c.onEventChanged(obj);

        expect(obj.clearEventOnEventChange).toBe(true);
        expect(c.onCheckboxChange).toHaveBeenCalledWith(obj);
    });

    it('should change nothing of checkboxex, when there is something checked', function() {
        var c = controller();
        c.onCheckboxChange = jasmine.createSpy();
        service.isDuplicated = _.constant(false);
        var obj = {
            error: _.noop,
            eventToClear: {},
            clearDueDateOnDueDateChange: false,
            clearDueDateOnEventChange: true,
            clearEventOnDueDateChange: false,
            clearEventOnEventChange: false
        };

        c.onEventChanged(obj);

        expect(obj.clearEventOnEventChange).toBe(false);
        expect(c.onCheckboxChange).toHaveBeenCalledWith(obj);
    });

    it('validate', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            clearEventOnEventChange: true,
            error: _.noop
        }]);
        service.findLastDuplicate = _.constant(null);
        c.form = {
            $validate: _.constant(true)
        };

        expect(c.topic.validate()).toBe(true);
    });
});
