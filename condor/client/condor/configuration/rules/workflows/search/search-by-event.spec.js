describe('inprotech.configuration.rules.workflows.ipSearchByEventController', function() {
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
                return $controller('ipSearchByEventController');
            };
        });
    });

    describe('initialisation', function() {
        it('should initialise controller via the characteristics service', function() {
            var c = controller();
            c.$onInit();
            expect(charsService.initController).toHaveBeenCalledWith(c, 'event', {
                applyTo: null,
                matchType: 'exact-match'
            });
        });
    });
});
