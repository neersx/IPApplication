describe('inprotech.configuration.rules.workflows.ipSearchByCharacteristicsController', function() {
    'use strict';

    var controller, charsService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows']);
            charsService = $injector.get('workflowsCharacteristicsServiceMock');
            $provide.value('workflowsCharacteristicsService', charsService);
        });

        inject(function($controller) {
            controller = function() {
                var c = $controller('ipSearchByCharacteristicsController');
                c.$onInit();
                return c;
            };
        });
    });

    describe('initialisation', function() {
        it('should initialise controller via the characteristics service', function() {
            var c = controller();

            expect(charsService.initController).toHaveBeenCalledWith(c, 'characteristics', {
                applyTo: null,
                matchType: 'exact-match'
            });
        });

        it('should set focus on office when has offices', function() {
            charsService.initController.and.callFake(function(vm) {
                vm.hasOffices = true;
            });

            var c = controller();

            expect(c.hasAutofocusOnOffice).toBe(true);
            expect(c.hasAutofocusOnCaseType).toBe(false);
        });

        it('should set focus on case type when no offices', function() {
            charsService.initController.and.callFake(function(vm) {
                vm.hasOffices = false;
            });

            var c = controller();

            expect(c.hasAutofocusOnOffice).toBe(false);
            expect(c.hasAutofocusOnCaseType).toBe(true);
        });
    });
});
