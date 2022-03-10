describe('inprotech.configuration.rules.workflows.ipSearchByCriteriaController', function() {
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
                return $controller('ipSearchByCriteriaController');
            };
        });
    });

    describe('initialisation', function() {
        it('should initialise controller via the characteristics service', function() {
            var c = controller();
            c.$onInit();
            expect(charsService.initController).toHaveBeenCalledWith(c, 'criteria', []);
        });
    });
});
