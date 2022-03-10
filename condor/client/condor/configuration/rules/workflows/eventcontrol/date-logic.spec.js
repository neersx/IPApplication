describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlDateLogic', function() {
    'use strict';

    var controller, kendoGridBuilder, service;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.grid', 'inprotech.mocks.configuration.rules.workflows']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('workflowsEventControlServiceMock');
            $provide.value('workflowsEventControlService', service);
        });
    });

    beforeEach(inject(function($componentController) {
        controller = function() {
            var topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        eventId: -222,
                        canEdit: true
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlDateLogic', {
                $scope: {},
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
        it('should initialise', function() {
            var c = controller();

            expect(c.canEdit).toBe(true);
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });

        it('should read grid data from sevice', function(){
            var c = controller();

            c.gridOptions.read();
            expect(service.getDateLogicRules).toHaveBeenCalledWith(-111, -222);
        });
    });
});
