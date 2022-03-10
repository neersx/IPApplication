describe('inprotech.configuration.general.jurisdictions.ClassDetailController', function() {
    'use strict';

    var controller, kendoGridBuilder;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    content: {
                        class: 'A',
                        description: 'Class A',
                        intClasses: '01,02',
                        internationalClasses: [{
                            class: '01',
                            description: 'Int Class A'
                        }, {
                            class: '02',
                            description: 'Int Class B'
                        }],
                        notes: 'Class A Notes'
                    },
                    hasIntClasses: true
                }
            }, dependencies);

            var c = $controller('ClassDetailController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function() {
        it('initialises properties and international classes where required', function() {
            var c = controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.notes).toEqual('Class A Notes');
            expect(c.hasIntClasses).toBe(true);
            expect(_.pluck(c.gridOptions.columns, 'field')).toEqual(['code', 'value']);
        });
        it('hides international classes where not required', function() {
            var c = controller({
                $scope: {
                    content: {
                        class: 'B',
                        description: 'Class B',
                        notes: 'Class B Notes'
                    },
                    hasIntClasses: false
                }
            });
            expect(kendoGridBuilder.buildOptions).not.toHaveBeenCalled();
            expect(c.gridOptions).not.toBeDefined();
            expect(c.notes).toEqual('Class B Notes');
            expect(c.hasIntClasses).toBe(false);
        });
    });
});