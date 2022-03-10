describe('inprotech.processing.policing.ipPolicingRateGraphController', function() {
    'use strict';

    var controller, kendoBarChartBuilder, scope;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.processing.policing', 'inprotech.mocks.components.barchart']);

            kendoBarChartBuilder = $injector.get('kendoBarChartBuilderMock');
            $provide.value('kendoBarChartBuilder', kendoBarChartBuilder);
        });
    });

    beforeEach(inject(function($rootScope) {
        scope = $rootScope.$new();
    }));

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                rateGraphItemFormatterService: {
                    format: angular.noop
                }
            }, dependencies);

            var c = $controller('ipPolicingRateGraphController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('on load', function() {
        it('should initialise', function() {
            var c = controller();

            expect(kendoBarChartBuilder.buildOptions).toHaveBeenCalled();
            expect(c.rateGraph.error).toBe(false);
            expect(c.rateGraph.historicalDataAvailable).toBe(true);
        });

        it('should disable transition because it is annoying for regular refresh', function() {
            controller();

            var options = kendoBarChartBuilder.buildOptions.calls.first().args[0];

            expect(options.transitions).toEqual(false);
        });

        it('should set up series for what enters and exits policing queue', function() {
            controller();

            var options = kendoBarChartBuilder.buildOptions.calls.first().args[0];

            expect(options.sort.field).toEqual('timeSlot');
            expect(options.sort.dir).toEqual('asc');
        });
    });
});