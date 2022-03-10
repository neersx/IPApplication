describe('inprotech.processing.policing.ipCurrentStatusGraphController', function() {
    'use strict';

    var controller, kendoBarChartBuilder, scope;
    var appContext = {
        user: {
            preferences: {
                dateFormat: 'dd-MMM-yy'
            }
        },
        then: function(cb) {
            cb(appContext);
        }
    };

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
                statusGraphDataAdapterService: {
                    getCategories: angular.noop
                }
            }, dependencies);

            var c = $controller('ipCurrentStatusGraphController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('on load', function() {
        it('should initialise', function() {
            controller();

            expect(kendoBarChartBuilder.buildOptions).toHaveBeenCalled();
        });

        it('should disable transition because it is annoying for regular refresh', function() {
            controller();

            var options = kendoBarChartBuilder.buildOptions.calls.first().args[0];

            expect(options.transitions).toEqual(false);
        });

        it('should set up series for what enters and exits policing queue', function() {
            controller();

            var options = kendoBarChartBuilder.buildOptions.calls.first().args[0];

            expect(options.series[0].field).toEqual('stuck');
            expect(options.series[1].field).toEqual('tolerable');
            expect(options.series[2].field).toEqual('fresh');
        });
    });
});
