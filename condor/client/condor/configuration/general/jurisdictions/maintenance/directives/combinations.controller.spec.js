describe('inprotech.configuration.general.jurisdictions.ValidCombinationsController', function() {
    'use strict';

    var controller, service;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions']);

            service = $injector.get('JurisdictionValidCombinationsServiceMock');
            $provide.value('jurisdictionCombinationsService', service);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('ValidCombinationsController', {
                $scope: {
                    parentId: 'AU',
                    parentName: 'Australia'
                }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function() {
        it('should initialise the properties', function() {

            service.hasCombinations.returnValue = {
                            hasCombinations: false
                        };

            var c = controller();
            expect(c.parentId).toBe('AU')
            expect(c.parentName).toBe('Australia');
            expect(c.hasValidCombinations).toBe(false);
            expect(service.hasCombinations).toHaveBeenCalledWith('AU');
        });
        it('should set hasCombinations correctly', function() {
            
            service.hasCombinations.returnValue = {
                            hasCombinations: true
                        };

            var c = controller();            
            expect(c.parentId).toBe('AU')
            expect(c.parentName).toBe('Australia');
            expect(c.hasValidCombinations).toBe(true);
            expect(service.hasCombinations).toHaveBeenCalledWith('AU');
        });
    })
});
