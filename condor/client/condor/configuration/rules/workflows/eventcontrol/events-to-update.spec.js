describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlEventsToUpdate', function() {
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
                        criteriaId: 1,
                        eventId: 2,
                        syncedEventSettings: {
                            dateAdjustmentOptions: []
                        }
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlEventsToUpdate', {
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

        expect(c.criteriaId).toEqual(1);
        expect(c.eventId).toEqual(2);
        expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
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

    it('getFormData', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            added: true,
            sequence: 1,
            eventToUpdate: {
                key: 2
            },
            relativeCycle: 3,
            adjustDate: 4          
        }]);

        var r = c.topic.getFormData();

        expect(r).toEqual({
            eventsToUpdateDelta: {
                added: [{
                    sequence: 1,
                    eventToUpdateId: 2,
                    relativeCycle: 3,
                    adjustDate: 4
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
            eventToUpdate: {
                maxCycles: 1
            }
        };

        c.onEventChanged(obj);

        expect(service.getDefaultRelativeCycle).toHaveBeenCalled()
    });

    it('validate', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{            
            error: _.noop
        }]);
        service.findLastDuplicate = _.constant(null);
        c.form = {
            $validate: _.constant(true)
        };

        expect(c.topic.validate()).toBe(true);
    });
});
